FROM alpine3.8-base

# need testing repo for k8s
RUN echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN apk add --update --no-cache --initdb \
    kubernetes docker ebtables ethtool socat iproute2 etcd

RUN rm -rf /var/cache/apk && mkdir -p /var/cache/apk

# Deleted cached packages
RUN rm -rf /var/cache/apk/* && mkdir -p /var/cache/apk

# Our local files
COPY files/init /init
COPY files/etc/ /etc/

# kubernetes settings
COPY files/scripts/kube-init.sh /root/kube-init.sh
