FROM ubuntu:16.04 AS kernel
RUN apt-get update && \
    apt-get install -y linux-virtual && \
    apt-get clean

FROM ubuntu:16.04 AS install
ARG SSHPUBKEY

USER root
RUN mkdir -p /etc/ssh /root/.ssh && chmod 0700 /root/.ssh
RUN echo $SSHPUBKEY > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys

COPY --from=kernel /lib/modules /lib/modules

COPY --from=kernel /boot/vmlinuz-* /vmlinuz

RUN apt-get update && \
    apt-get install -y ca-certificates util-linux openssh-server openssh-client \
                       rng-tools dhcpcd5 && \
    apt-get clean

RUN update-rc.d ssh defaults && update-rc.d ssh enable
RUN update-rc.d rng-tools defaults && update-rc.d rng-tools enable
RUN update-rc.d dhcpcd defaults && update-rc.d dhcpcd enable

COPY files/init /init
COPY files/etc/init /etc/init

RUN sed -i 's/root:!/root:*/' /etc/shadow

RUN sed -i '/floppy:x:11:root/d' /etc/group
