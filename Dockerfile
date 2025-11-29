FROM alpine:latest
RUN apk add --no-cache curl bash
CMD bash <(curl -Ls https://raw.githubusercontent.com/fscarmen/sba/main/docker.sh)
