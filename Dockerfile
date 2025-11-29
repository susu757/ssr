FROM alpine:latest
WORKDIR /app

# 1. 安装基础工具
RUN apk add --no-cache curl wget bash

# 2. 下载官方 Cloudflared (绝对稳定)
RUN wget -q -O /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/bin/cloudflared

# 3. 下载官方 Sing-box (绝对稳定)
RUN wget -q -O sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.0/sing-box-1.9.0-linux-amd64.tar.gz && \
    tar -xzf sing-box.tar.gz && mv sing-box-*/sing-box /usr/bin/sing-box && chmod +x /usr/bin/sing-box

# 4. 生成配置文件并启动
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "{\"inbounds\":[{\"type\":\"vless\",\"tag\":\"vless-in\",\"listen\":\"::\",\"listen_port\":8080,\"users\":[{\"uuid\":\"$UUID\"}]}],\"outbounds\":[{\"type\":\"direct\"}]}" > config.json' >> /start.sh && \
    echo 'sing-box run -c config.json &' >> /start.sh && \
    echo 'cloudflared tunnel run --token $ARGO_AUTH' >> /start.sh && \
    chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
