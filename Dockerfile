FROM alpine:latest
WORKDIR /app

# 安装核心依赖 (使用 APK，体积最小)
RUN apk update && apk upgrade && \
    apk add --no-cache bash curl wget ca-certificates tar && \
    
    # 1. 下载 Cloudflared (官方源 - Direct Wget)
    wget -qO /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/bin/cloudflared && \
    
    # 2. 下载 Sing-box (官方源，确保版本是最新的稳定版)
    # 当前版本为 1.9.0 (请注意版本号可能需要根据最新稳定版进行微调)
    wget -qO singbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.0/sing-box-1.9.0-linux-amd64.tar.gz && \
    tar -xzf singbox.tar.gz && \
    mv sing-box-*/sing-box /usr/bin/sing-box && \
    chmod +x /usr/bin/sing-box && \
    rm -rf sing-box-* singbox.tar.gz

# Final setup: 创建启动脚本 (使用 HereDoc 安全地生成 JSON 配置)
RUN echo '#!/bin/bash' > /start.sh && \
    # 1. 生成 Sing-box Config (VLESS/WS Inbound)
    echo 'cat > config.json <<EOF' >> /start.sh && \
    echo '{' >> /start.sh && \
    echo '  "inbounds": [{' >> /start.sh && \
    echo '    "type": "vless",' >> /start.sh && \
    echo '    "tag": "vless-in",' >> /start.sh && \
    echo '    "listen": "::",' >> /start.sh && \
    echo '    "listen_port": 8080,' >> /start.sh && \
    echo '    "users": [{"uuid": "${UUID}"}],' >> /start.sh && \
    echo '    "transport": {"type": "ws", "path": "/"}' >> /start.sh && \
    echo '  }],' >> /start.sh && \
    echo '  "outbounds": [{"type": "direct"}]' >> /start.sh && \
    echo '}' >> /start.sh && \
    echo 'EOF' >> /start.sh && \
    # 2. 启动服务 (Sing-box & Cloudflared)
    echo 'sing-box run -c config.json &' >> /start.sh && \
    echo 'cloudflared tunnel run --token $ARGO_AUTH' >> /start.sh && \
    chmod +x /start.sh

# 启动命令
CMD ["/bin/bash", "/start.sh"]
