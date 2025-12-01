FROM alpine:latest
WORKDIR /app

# 安装核心依赖 (使用 APK，体积最小)
RUN apk update && apk upgrade && \
    apk add --no-cache bash curl wget ca-certificates tar && \
    
    # 1. 下载 Cloudflared (官方源 - Direct Wget)
    wget -qO /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/bin/cloudflared && \
    
    # 2. 下载 Sing-box (官方源)
    wget -qO singbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.0/sing-box-1.9.0-linux-amd64.tar.gz && \
    tar -xzf singbox.tar.gz && \
    mv sing-box-*/sing-box /usr/bin/sing-box && \
    chmod +x /usr/bin/sing-box && \
    rm -rf sing-box-* singbox.tar.gz

# Final setup: 创建启动脚本 (VLESS/WS + Argo)
RUN echo '#!/bin/bash' > /start.sh && \
    # 1. 生成 Sing-box Config (VLESS/WS Inbound)
    echo 'echo "{\"inbounds\":[{\"type\":\"vless\",\"tag\":\"vless-in\",\"listen\":"::",\"listen_port\":8080,\"users\":[{\"uuid\":\"$UUID\"}],\"transport\":{\"type\":\"ws\",\"path\":\"/\"}}],\"outbounds\":[{\"type\":\"direct\"}]}" > config.json' >> /start.sh && \
    # 2. 启动服务 (Sing-box & Cloudflared)
    echo 'sing-box run -c config.json &' >> /start.sh && \
    echo 'cloudflared tunnel run --token $ARGO_AUTH' >> /start.sh && \
    chmod +x /start.sh

# 启动命令
CMD ["/bin/bash", "/start.sh"]
