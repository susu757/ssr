# 切换到兼容性更好的 Ubuntu 20.04 Focal
FROM ubuntu:20.04

# 设置环境
ENV DEBIAN_FRONTEND=noninteractive

# 核心安装块：使用 WGET (直接下载官方二进制文件，绕开 APT 仓库冲突)
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl wget bash ca-certificates uuid-runtime procps iproute2 tar net-tools wireguard openresolv && \
    
    # 1. 下载 Cloudflared (官方源 - Direct Wget)
    wget -qO /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/bin/cloudflared && \
    
    # 2. 下载 Sing-box (官方源)
    wget -qO singbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.0/sing-box-1.9.0-linux-amd64.tar.gz && \
    tar -xzf singbox.tar.gz && \
    mv sing-box-*/sing-box /usr/bin/sing-box && \
    chmod +x /usr/bin/sing-box && \
    
    # 3. 下载 WARP-GO 客户端 (替代 warp-cli，实现 WARP 功能)
    wget -qO /usr/bin/warp-cli https://github.com/ViRb3/warp-cli/releases/download/v1.1.2/warp-cli_1.1.2_amd64 && \
    chmod +x /usr/bin/warp-cli && \
    
    # 清理缓存
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Final setup: 启动脚本 (手动配置 WARP 接口)
RUN echo '#!/bin/bash' > /start.sh && \
    # 1. 启动 WARP 接口 (使用第三方 CLI 解决 APT 依赖问题)
    echo 'warp-cli register && warp-cli set-mode proxy' >> /start.sh && \
    echo 'warp-cli connect' >> /start.sh && \
    echo 'sleep 10' >> /start.sh && \
    # 2. 生成 Sing-box Config (VLESS/WS Inbound)
    echo 'echo "{\"inbounds\":[{\"type\":\"vless\",\"tag\":\"vless-in\",\"listen\":\"::\",\"listen_port\":8080,\"users\":[{\"uuid\":\"$UUID\"}],\"transport\":{\"type\":\"ws\",\"path\":\"/\"}}],\"outbounds\":[{\"type\":\"socks\",\"tag\":\"warp-proxy\",\"server_address\":\"127.0.0.1\",\"server_port\":40000},{\"type\":\"direct\"}]}" > config.json' >> /start.sh && \
    # 3. 启动服务 (Sing-box & Cloudflared)
    echo 'sing-box run -c config.json &' >> /start.sh && \
    echo 'cloudflared tunnel run --token $ARGO_AUTH' >> /start.sh && \
    chmod +x /start.sh

# 启动命令
CMD ["/bin/bash", "/start.sh"]
