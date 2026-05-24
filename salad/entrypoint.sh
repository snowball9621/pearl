#!/usr/bin/env bash
set -euo pipefail

WALLET="${WALLET:-prl1pvgs56cfqzkfzqjgm6npgw3j5jc3w8ra2uk6ysdum58qpzmnanzmsfs4kjz}"
POOL_HOST="${POOL_HOST:-eu1.alphapool.tech}"
POOL_PORT="${POOL_PORT:-5566}"
POOL="${POOL:-stratum+tcp://${POOL_HOST}:${POOL_PORT}}"
DIFF="${DIFF:-524288}"
STATUS_INTERVAL="${STATUS_INTERVAL:-30}"
LOG_DIR="${LOG_DIR:-/var/log/pearl}"
RUN_DIR="${RUN_DIR:-/var/run/pearl}"
MONITOR_URL="${MONITOR_URL:-http://203.55.176.251:8080/api/heartbeat}"
MONITOR_TOKEN="${MONITOR_TOKEN:-}"

mkdir -p "$LOG_DIR" "$RUN_DIR"

if [ -z "${DEVICES:-}" ] || [ "${DEVICES:-all}" = "all" ]; then
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "nvidia-smi not found; the container is not running with GPU access" >&2
    exit 1
  fi
  DEVICES="$(nvidia-smi --query-gpu=index --format=csv,noheader,nounits | tr -d ' ' | paste -sd, -)"
fi

if [ -z "$DEVICES" ]; then
  echo "no NVIDIA GPU devices found" >&2
  exit 1
fi

machine_hint="${SALAD_MACHINE_ID:-${HOSTNAME:-container}}"
MACHINE_ID="${MACHINE_ID:-salad-${machine_hint}}"
WORKER="${WORKER:-${WORKER_PREFIX:-salad}-${machine_hint}}"
LOG_FILE="$LOG_DIR/miner.log"

heartbeat() {
  python3 - "$LOG_FILE" <<'PY'
import datetime as dt
import json
import os
import re
import subprocess
import sys
import time
import urllib.request

log_file = sys.argv[1]
monitor_url = os.environ.get("MONITOR_URL", "").rstrip("/")
monitor_token = os.environ.get("MONITOR_TOKEN", "")
machine_id = os.environ.get("MACHINE_ID", "salad-container")
wallet = os.environ.get("WALLET", "")

def run(cmd):
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""

def parse_gpus():
    out = run([
        "nvidia-smi",
        "--query-gpu=index,name,utilization.gpu,power.draw,memory.used,memory.total",
        "--format=csv,noheader,nounits",
    ])
    gpus = []
    for line in out.splitlines():
        parts = [p.strip() for p in line.split(",")]
        if len(parts) < 6:
            continue
        try:
            gpus.append({
                "index": int(parts[0]),
                "name": parts[1],
                "utilization_gpu": float(parts[2]),
                "power_w": float(parts[3]),
                "memory_used_mib": float(parts[4]),
                "memory_total_mib": float(parts[5]),
            })
        except ValueError:
            pass
    return gpus

def read_recent_log():
    try:
        with open(log_file, "r", encoding="utf-8", errors="ignore") as fh:
            lines = fh.readlines()[-400:]
    except FileNotFoundError:
        return [], 0.0, "", 0, "", 0, 0
    hashrate = 0.0
    last_share = ""
    last_share_epoch = 0
    last_warn = ""
    now = time.time()
    shares_recent = 0
    warns_recent = 0
    for line in lines:
        m = re.search(r"hashrate_th_s=([0-9.]+)", line)
        if m:
            hashrate = float(m.group(1))
        ts_match = re.match(r"(\d{4}-\d{2}-\d{2}T[0-9:.]+Z)", line)
        epoch = 0
        if ts_match:
            try:
                epoch = dt.datetime.fromisoformat(ts_match.group(1).replace("Z", "+00:00")).timestamp()
            except ValueError:
                epoch = 0
        low = line.lower()
        if "share" in low and ("submitted" in low or "accepted" in low):
            last_share = ts_match.group(1) if ts_match else ""
            last_share_epoch = int(epoch)
            if epoch and now - epoch <= 300:
                shares_recent += 1
        if any(x in low for x in ("warn", "error", "connection_lost", "reconnect", "dropped")):
            last_warn = line.strip()[:300]
            if epoch and now - epoch <= 300:
                warns_recent += 1
    return lines[-30:], hashrate, last_share, last_share_epoch, last_warn, shares_recent, warns_recent

def post_once():
    if not monitor_url or not monitor_token:
        return
    lines, hashrate, last_share, last_share_epoch, last_warn, shares_recent, warns_recent = read_recent_log()
    now = int(time.time())
    gpus = parse_gpus()
    payload = {
        "id": machine_id,
        "hostname": os.environ.get("HOSTNAME", ""),
        "ssh_host": "salad",
        "ssh_port": "",
        "wallet": wallet,
        "time_epoch": now,
        "time_iso": dt.datetime.utcfromtimestamp(now).isoformat(timespec="seconds") + "Z",
        "gpus": gpus,
        "gpu_count": len(gpus),
        "tunnel_ok": True,
        "tunnel_proc": 0,
        "miner_proc": 1 if run(["pgrep", "-f", "alpha-miner"]) else 0,
        "logs": [],
        "shares_recent": shares_recent,
        "warns_recent": warns_recent,
        "last_share": last_share,
        "last_share_epoch": last_share_epoch,
        "last_warn": last_warn,
        "hashrate_th_s": hashrate,
    }
    req = urllib.request.Request(
        monitor_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": "Bearer " + monitor_token,
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        urllib.request.urlopen(req, timeout=8).read()
    except Exception as exc:
        print("heartbeat failed:", exc, flush=True)

while True:
    post_once()
    time.sleep(int(os.environ.get("HEARTBEAT_INTERVAL", "30")))
PY
}

export WALLET MONITOR_URL MONITOR_TOKEN MACHINE_ID
heartbeat &
echo $! > "$RUN_DIR/heartbeat.pid"

echo "starting alpha-miner"
echo "wallet=$WALLET"
echo "pool=$POOL"
echo "devices=$DEVICES"
echo "worker=$WORKER"

exec /usr/local/bin/alpha-miner \
  --devices "$DEVICES" \
  --pool "$POOL" \
  --address "$WALLET" \
  --worker "$WORKER" \
  --password "x;d=${DIFF}" \
  --status-interval "$STATUS_INTERVAL" \
  ${MINER_ARGS:-} \
  2>&1 | tee -a "$LOG_FILE"
