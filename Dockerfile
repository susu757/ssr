FROM alpine:latest
WORKDIR /app

# 1. 安装基础工具
RUN apk add --no-cache curl wget bash

# 2. 下载官方 Cloudflared
RUN wget -q -O /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/bin/cloudflared

# 3. 下载官方 Sing-box
RUN wget -q -O sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.0/sing-box-1.9.0-linux-amd64.tar.gz && \
    tar -xzf sing-box.tar.gz && mv sing-box-*/sing-box /usr/bin/sing-box && chmod +x /usr/bin/sing-box

# 4. 启动脚本 (包含链接生成功能)
RUN echo '#!/bin/bash' > /start.sh && \
    # 生成节点配置文件
    echo 'echo "{\"inbounds\":[{\"type\":\"vless\",\"tag\":\"vless-in\",\"listen\":\"::\",\"listen_port\":8080,\"users\":[{\"uuid\":\"$UUID\"}]}],\"outbounds\":[{\"type\":\"direct\"}]}" > config.json' >> /start.sh && \
    # === 核心：生成并打印链接 ===
    echo 'echo ""' >> /start.sh && \
    echo 'echo "========================================================="' >> /start.sh && \
    echo 'echo "🎉 节点部署成功！请复制下方 VLESS 链接导入软件："' >> /start.sh && \
    echo 'echo "---------------------------------------------------------"' >> /start.sh && \
    echo 'echo "vless://${UUID}@${ARGO_DOMAIN}:443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=tcp&fp=chrome#Koyeb-Node"' >> /start.sh && \
    echo 'echo "---------------------------------------------------------"' >> /start.sh && \
    echo 'echo "========================================================="' >> /start.sh && \
    echo 'echo ""' >> /start.sh && \
    # 启动服务
    echo 'sing-box run -c config.json & cloudflared tunnel run --token $ARGO_AUTH' >> /start.sh && \
    chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
