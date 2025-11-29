# 切换到兼容性最好的 Ubuntu 20.04 Focal
FROM ubuntu:20.04

# 设置环境
ENV DEBIAN_FRONTEND=noninteractive

# 核心安装块
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl wget bash ca-certificates uuid-runtime gnupg2 procps iproute2 && \
    
    # 1. 安装 WARP-CLI (必须通过 APT，使用官方源)
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    # 注意：这里我们使用 focal main，这是 Ubuntu 20.04 的代号
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ focal main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt-get update && \
    # 强制安装 warp-cli (这是唯一的 APT 依赖)
    apt-get install -y warp-cli && \
    
    # 2. 下载 Cloudflared (官方源 - Direct Wget，绕开 APT 冲突)
    wget -q -O /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/bin/cloudflared && \
    
    # 3. 下载 Sing-box (官方源)
    wget -qO singbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.0/sing-box-1.9.0-linux-amd64.tar.gz && \
    tar -xzf singbox.tar.gz && \
    mv sing-box-*/sing-box /usr/bin/sing-box && \
    chmod +x /usr/bin/sing-box && \
    # 清理缓存
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Final setup: 启动脚本
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'warp-cli set-mode tunnel && warp-cli set-proxy-mode remote && warp-cli connect' >> /start.sh && \
    echo 'sleep 10' >> /start.sh && \
    echo 'echo "{\"inbounds\":[{\"type\":\"vless\",\"tag\":\"vless-in\",\"listen\":\"::\",\"listen_port\":8080,\"users\":[{\"uuid\":\"$UUID\"}],\"transport\":{\"type\":\"ws\",\"path\":\"/\"}}],\"outbounds\":[{\"type\":\"direct\"}]}" > config.json' >> /start.sh && \
    echo 'sing-box run -c config.json &' >> /start.sh && \
    echo 'cloudflared tunnel run --token $ARGO_AUTH' >> /start.sh && \
    chmod +x /start.sh

# 启动命令
CMD ["/bin/bash", "/start.sh"]
