FROM alpine:3.8.4 AS openrc
RUN mkdir -p /lib/apk/db /run
RUN apk add --no-cache --initdb openrc

FROM alpine:3.8.4 AS kernel
RUN mkdir -p /lib/apk/db /run
RUN apk add --no-cache --initdb linux-virt virtualbox-guest-modules-virt

FROM alpine:3.8.4 AS install
USER root
# the public key that is authorized to connect to this instance.
ARG SSHPUBKEY
# optional packages
ARG PKGS

# don't want all the /etc stuff from openrc -- only tools
# https://pkgs.alpinelinux.org/contents?repo=main&page=2&arch=x86_64&branch=v3.8&name=openrc
COPY --from=openrc /lib/ /lib/
COPY --from=openrc /bin /bin
COPY --from=openrc /sbin /sbin
COPY --from=openrc /etc/ /etc/

# Need virtio modules for networking
COPY --from=kernel /lib/modules /lib/modules

# Copy kernel for later use
COPY --from=kernel /boot/vmlinuz-virt /vmlinuz

RUN mkdir -p /lib/apk/db /run
RUN apk add --update --no-cache --initdb alpine-baselayout apk-tools busybox ca-certificates util-linux \
    openssh openssh-client rng-tools dhcpcd virtualbox-guest-additions 
RUN [ ! -z "$PKGS" ] && apk add --no-cache $PKGS || echo "No optional pkgs provided."

ARG NH_VER=3.6.1

RUN \
  apk --no-cache add byacc curl flex gcc groff linux-headers make musl-dev ncurses-dev && \
  curl -sL https://nethack.org/download/${NH_VER}/nethack-${NH_VER//.}-src.tgz | tar zxf - && \
  ( \
    cd nethack-${NH_VER} && \
    sed -i -e 's/cp -n/cp/g' -e '/^PREFIX/s:=.*:=/usr:' sys/unix/hints/linux && \
    sh sys/unix/setup.sh sys/unix/hints/linux && \
    make all && \
    make install \
  ) && \
  rm -rf nethack-${NH_VER}

# Deleted cached packages
RUN rm -rf /var/cache/apk/*

# Our local files
COPY files/init /init

RUN echo "RNGD_OPTS=\"-f -r /dev/urandom\"" > /etc/conf.d/rngd
RUN echo "Welcome to slim!" > /etc/motd
RUN echo "tty0::respawn:/sbin/agetty -a root -L tty0 38400 vt100" > /etc/inittab
RUN echo "ttyS0::respawn:/sbin/agetty -a root -L ttyS0 115200 vt100" >> /etc/inittab

# Set an ssh key
RUN mkdir -p /etc/ssh /root/.ssh && chmod 0700 /root/.ssh
RUN echo $SSHPUBKEY > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys

# Fix ssh
RUN sed -i 's/root:!/root:*/' /etc/shadow
