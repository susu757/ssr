FROM ubuntu:20.04

# 设置环境
ENV DEBIAN_FRONTEND=noninteractive

# 核心安装块：只安装 Cloudflared 和 Sing-box (稳定版)
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl wget bash ca-certificates uuid-runtime procps iproute2 net-tools tar && \
    
    # 1. 下载 Cloudflared (官方源 - Direct Wget)
    wget -qO /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/bin/cloudflared && \
    
    # 2. 下载 Sing-box (官方源)
    wget -qO singbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.0/sing-box-1.9.0-linux-amd64.tar.gz && \
    tar -xzf singbox.tar.gz && \
    mv sing-box-*/sing-box /usr/bin/sing-box && \
    chmod +x /usr/bin/sing-box && \
    
    # 清理缓存
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Final setup: 创建启动脚本 (纯 VLESS/WS + Argo)
RUN echo '#!/bin/bash' > /start.sh && \
    # 1. 生成 Sing-box Config (VLESS/WS Inbound)
    echo 'echo "{\"inbounds\":[{\"type\":\"vless\",\"tag\":\"vless-in\",\"listen\":\"::\",\"listen_port\":8080,\"users\":[{\"uuid\":\"$UUID\"}],\"transport\":{\"type\":\"ws\",\"path\":\"/\"}}],\"outbounds\":[{\"type\":\"direct\"}]}" > config.json' >> /start.sh && \
    # 2. 启动服务 (Sing-box & Cloudflared)
    echo 'sing-box run -c config.json &' >> /start.sh && \
    echo 'cloudflared tunnel run --token $ARGO_AUTH' >> /start.sh && \
    chmod +x /usr/bin/start.sh

# 启动命令
CMD ["/bin/bash", "/start.sh"]
