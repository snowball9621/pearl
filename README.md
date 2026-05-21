# Pearl GPU Miner Quick Deploy

一套给新 GPU 机器快速部署 Pearl/PRL 挖矿的脚本，默认已经集成：

- 默认钱包地址：`prl1pvgs56cfqzkfzqjgm6npgw3j5jc3w8ra2uk6ysdum58qpzmnanzmsfs4kjz`
- 默认中转 VPS：`203.55.176.251`
- 默认中转链路：本机 `127.0.0.1:15566` -> VPS -> `sg1.alphapool.tech:5566`
- 多卡自动启动：每张 GPU 一个进程
- 守护：GPU 空闲、进程少、太久没提交 share 时自动重启
- 可选监控面板心跳：配置 `MONITOR_TOKEN` 后自动上报

不要把 VPS 密码、面板 TOKEN、SSH 私钥提交到仓库。

## 新机器一键部署

```bash
git clone https://github.com/snowball9621/pearl.git
cd pearl
sudo bash install.sh
sudo pearl-up
sudo pearl-status
```

如果这台机器还不能免密 SSH 到中转 VPS，先在 GPU 机器上做一次：

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id root@203.55.176.251
ssh root@203.55.176.251 "echo ok"
```

然后再执行：

```bash
sudo pearl-up
```

## 常用命令

```bash
sudo pearl-up                    # 启动隧道、挖矿、守护、可选心跳
sudo pearl-start                 # 只启动隧道和挖矿
sudo pearl-status                # 查看 GPU、进程、隧道和日志
sudo pearl-watchdog status       # 查看守护状态
sudo pearl-watchdog restart      # 重启守护
sudo pearl-monitor-heartbeat once # 测试面板心跳
sudo pearl-stop                  # 停止挖矿、守护、心跳和隧道
```

## 配置

安装后配置文件在：

```bash
/etc/pearl/pearl.env
```

默认配置来自 `config.env.example`。如果要在安装前改配置：

```bash
cp config.env.example config.env
nano config.env
sudo bash install.sh
```

常改字段：

```bash
WALLET=你的PRL钱包地址
RELAY_HOST=203.55.176.251
RELAY_REMOTE_HOST=sg1.alphapool.tech
RELAY_REMOTE_PORT=5566
MONITOR_TOKEN=
MACHINE_ID=
```

如果不用中转，改成：

```bash
USE_RELAY=0
POOL_HOST=sg1.alphapool.tech
POOL_PORT=5566
```

## 日志位置

```bash
/var/log/pearl/gpu0.log
/var/log/pearl/gpu1.log
/var/log/pearl/watchdog.log
/var/log/pearl/tunnel.log
/var/log/pearl/heartbeat.log
```

## 新机器最短流程

镜像里已经有 SSH key，能连中转 VPS 的情况下：

```bash
git clone https://github.com/snowball9621/pearl.git && cd pearl
sudo bash install.sh
sudo pearl-up
```
