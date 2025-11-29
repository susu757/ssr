FROM alpine:latest
WORKDIR /app
# 确保安装了 bash, curl, wget 等基础工具
RUN apk add --no-cache curl wget bash ca-certificates tar

# 1. 下载 Cloudflared 官方二进制文件 (防止 404/403 封锁)
RUN wget -q -O /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/bin/cloudflared

# 2. 下载 Sing-box 官方二进制文件 (防止 404/403 封锁)
RUN wget -q -O sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.0/sing-box-1.9.0-linux-amd64.tar.gz && \
    tar -xzf sing-box.tar.gz && mv sing-box-*/sing-box /usr/bin/sing-box && chmod +x /usr/bin/sing-box && \
    rm -rf sing-box-* sing-box.tar.gz

# 3. 创建启动脚本 (/start.sh)
RUN echo '#!/bin/bash' > /start.sh && \
    # 生成 config.json - 关键：加入 transport":{"type":"ws","path":"/"}
    echo 'echo "{\"inbounds\":[{\"type\":\"vless\",\"tag\":\"vless-in\",\"listen\":\"::\",\"listen_port\":8080,\"users\":[{\"uuid\":\"$UUID\"}],\"transport\":{\"type\":\"ws\",\"path\":\"/\"}}],\"outbounds\":[{\"type\":\"direct\"}]}" > config.json' >> /start.sh && \
    echo 'echo \"VLESS Config Ready\"' >> /start.sh && \
    # 启动 Sing-box (后台运行)
    echo 'sing-box run -c config.json &' >> /start.sh && \
    # 启动 Cloudflared (前台运行，确保容器不退出)
    echo 'cloudflared tunnel run --token $ARGO_AUTH' >> /start.sh && \
    chmod +x /start.sh

# 默认启动命令
CMD ["/bin/bash", "/start.sh"]
