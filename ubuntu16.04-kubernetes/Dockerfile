FROM ubuntu16.04-base

RUN apt-get update && \
    apt-get install -y apt-transport-https curl gnupg-agent software-properties-common && \
    apt-get clean

# install docker and kubernetes
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" && \
    add-apt-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"

RUN apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io \
                       kubelet kubeadm kubectl && \
    apt-get clean && \
    apt-mark hold kubelet kubeadm kubectl

COPY files/scripts/kube-init.sh /root/kube-init.sh

# enable docker
RUN /lib/systemd/systemd-sysv-install enable docker

# set RAMDISK on docker
RUN sed -i -E '/\[Service\]/a \
                    Environment="DOCKER_RAMDISK=true"' \
                /lib/systemd/system/docker.service
