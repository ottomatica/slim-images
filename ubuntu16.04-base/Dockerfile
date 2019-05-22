FROM ubuntu:16.04
ARG SSHPUBKEY

USER root

RUN apt-get update && \
    apt-get install -y ca-certificates util-linux openssh-server openssh-client \
                       rng-tools dhcpcd5 kmod linux-virtual && \
    apt-get clean

# copy the kernel for later use
RUN rm /vmlinuz && cp /boot/vmlinuz-* /vmlinuz

RUN mkdir -p /etc/ssh /root/.ssh && chmod 0700 /root/.ssh
RUN echo $SSHPUBKEY > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# enable root autologin on tty1
RUN cp /lib/systemd/system/getty@.service /lib/systemd/system/autologin@.service && \
    sed -i -E 's/ExecStart=.+/ExecStart=-\/sbin\/agetty -a root %I 38400/' \
        /lib/systemd/system/autologin@.service && \
    ln -sf /lib/systemd/system/autologin@.service /etc/systemd/system/getty.target.wants/getty@tty1.service

# sshd requires /var/run/sshd to exist, but for some reason it doesn't get created
# and if we create it in the docker container, it ends up getting overwritten since it's
# a tmpfs.
RUN sed -i -E '/ExecStartPre=.+/i \
                    ExecStartPre=-/bin/mkdir -p \/var\/run\/sshd' \
                /lib/systemd/system/ssh.service

RUN sed -i 's/root:!/root:*/' /etc/shadow

RUN sed -i '/floppy:x:11:root/d' /etc/group

COPY files/init /init
