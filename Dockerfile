# 将基础系统更换为兼容性更好的 Ubuntu 20.04
FROM ubuntu:20.04

# 设置为非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 安装依赖、Cloudflare 服务和 Sing-box (使用 APT 官方源，更稳定)
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl wget bash ca-certificates uuid-runtime gnupg2 procps iproute2 && \
    
    # 1. 添加 Cloudflare 源并安装 Cloudflared/WARP (使用 Ubuntu Focal suite name)
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ focal main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    
    # 2. 核心安装 (这次会找到 cloudflared 和 warp-cli)
    apt-get update && \
    apt-get install -y cloudflared warp-cli && \
    
    # 3. 下载 Sing-box (官方源)
    wget -qO singbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.0/sing-box-1.9.0-linux-amd64.tar.gz && \
    tar -xzf singbox.tar.gz && \
    mv sing-box-*/sing-box /usr/bin/sing-box && \
    chmod +x /usr/bin/sing-box && \
    # 清理缓存
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Final setup: 创建启动脚本
RUN echo '#!/bin/bash' > /start.sh && \
    # 1. 启动 WARP 隧道 (解决IP跳动，让流量更稳定地从 CF 出口离开)
    echo 'warp-cli set-mode tunnel && warp-cli set-proxy-mode remote && warp-cli connect' >> /start.sh && \
    echo 'sleep 10' >> /start.sh && \
    # 2. 生成 Sing-box Config (VLESS/WS Inbound)
    echo 'echo "{\"inbounds\":[{\"type\":\"vless\",\"tag\":\"vless-in\",\"listen\":\"::\",\"listen_port\":8080,\"users\":[{\"uuid\":\"$UUID\"}],\"transport\":{\"type\":\"ws\",\"path\":\"/\"}}],\"outbounds\":[{\"type\":\"direct\"}]}" > config.json' >> /start.sh && \
    # 3. 启动服务 (Sing-box & Cloudflared)
    echo 'sing-box run -c config.json &' >> /start.sh && \
    echo 'cloudflared tunnel run --token $ARGO_AUTH' >> /start.sh && \
    chmod +x /start.sh

# 启动命令
CMD ["/bin/bash", "/start.sh"]
