# SaladCloud PRL Container

This image runs the AlphaPool PRL miner inside SaladCloud Container Engine.

Image after GitHub Actions builds:

```text
ghcr.io/snowball9621/pearl-salad:latest
```

Use one replica first. After it shows stable shares in Salad logs and AlphaPool, increase replicas.

## Salad Settings

Container image:

```text
ghcr.io/snowball9621/pearl-salad:latest
```

Environment variables:

```text
WALLET=prl1pvgs56cfqzkfzqjgm6npgw3j5jc3w8ra2uk6ysdum58qpzmnanzmsfs4kjz
POOL_HOST=eu1.alphapool.tech
POOL_PORT=5566
WORKER_PREFIX=salad-5090
```

Optional monitor variables:

```text
MONITOR_URL=http://203.55.176.251:8080/api/heartbeat
MONITOR_TOKEN=<your dashboard token>
MACHINE_ID=<optional fixed name>
```

Do not commit `MONITOR_TOKEN` to GitHub. Put it into Salad environment variables or secrets.

## Useful Overrides

Use a full pool URL:

```text
POOL=stratum+tcp://eu1.alphapool.tech:5566
```

Select devices:

```text
DEVICES=0
```

Extra miner args:

```text
MINER_ARGS=--sync-proof-submit
```

## Local Test

On a Docker host with NVIDIA Container Toolkit:

```bash
docker build -f salad/Dockerfile -t pearl-salad .
docker run --rm --gpus all \
  -e WALLET=prl1pvgs56cfqzkfzqjgm6npgw3j5jc3w8ra2uk6ysdum58qpzmnanzmsfs4kjz \
  pearl-salad
```

SaladCloud is a container platform, not an SSH server platform. The container starts automatically and logs to stdout.
