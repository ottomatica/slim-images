# Kubernetes

## Table of Contents
1. [Prerequisites](#prerequisites)
1. [Initialization](#initialization)
1. [VirtualBox Setup](#virtualbox-setup)
1. [Kubernetes Setup](#kubernetes-setup)
1. [Caveats](#caveats)
1. [References](#references)

## Prerequisites

- [`slim`](https://github.com/ottomatica/slim)
- [`slim-images`](https://github.com/ottomatica/slim-images)
- VirtualBox
- A lot of RAM (master node takes around 4gb, child nodes might be able to use less but 4gb is a safe default)

## Initialization

1. Clone the `slim` and `slim-images` repos

```bash
git clone https://github.com/ottomatica/slim-images
git clone https://github.com/ottomatica/slim
cd slim
```

2. Bootstrap the `alpine3.8-kubernetes` image

```bash
ln -s `pwd`/../slim-images/alpine3.8-kubernetes/ `pwd`/images/
slim build alpine3.8-kubernetes
```

3. Initialize the VirtualBox VMs

```bash
slim run master alpine3.8-kubernetes
slim run node1 alpine3.8-kubernetes # should be able to run any number of nodes
```

## VirtualBox Setup

*Note: These instructions are for the VirtualBox UI, but we should eventually automate it.*

1. Shutdown both `master` and `node1` (they will fail to boot anyways since the `initramfs` is too large for the standard 1024 MB RAM)
1. Navigate to File -> Preferences -> Network:
    1. Select the button on the right-hand bar with a `+` to add a new NAT network
    1. *optional* Right-click the newly added network and select `Edit NAT Network`
    1. *optional* Rename the network or change the Network CIDR if needed
    1. Select OK to close the dialog box
1. For each virtual machine:
    1. Right-click and select `Settings`
    1. Select the `System` tab, change the `Base Memory` to 4000 MB (Motherboard tab), and the number of processors to 2 (Processor tab)
    1. Select the `Network` tab, change the `Adapter 1` dropdown from `NAT` to `NAT Network`, and select the network you created earlier
    1. Select OK to close the dialog box
1. Start all virtual machines again in headless mode
1. For each virtual machine:
    1. Right-click and select `Show`
    1. In the resulting terminal, run `ip a` and note the IP address associated with `eth0`
    1. Navigate back to File -> Preferences -> Network
    1. Right-click on the network created earlier and select `Edit NAT Network`
    1. Select the `Port Forwarding` button
    1. In the dialog box, select the button on the right-hand bar with a `+` to add a new port-forward
    1. Choose a unique `Host Port` such as 2002 to use for ssh (make sure these ports differ for each port-forward), and enter the `Guest IP` noted above as well as `Guest Port` of 22
1. SSH into each virtual machine (recommended to have 2 terminals per VM, explained below)

```
ssh -i /home/`id -un`/.slim/baker_rsa root@127.0.0.1 -p [port from above] -o StrictHostKeyChecking=no
```

## Kubernetes Setup

1. For each **non-master** node, change the hostname to a unique hostname (ie nanobox1, nanobox2, etc.) using `hostname <new hostname>`
1. On the master node (**read all steps since they are somewhat time-dependent**):
    1. In the first terminal, run the `kube-init.sh` script in the home directory (this may take a moment as it downloads the docker images)
    1. In the second terminal, run the `kubelet.sh` script in the home directory **after the first terminal reaches a line like**: `[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s` (see the [Caveats](#caveats) section for more info)
    1. After the first terminal completes the kubernetes initialization, note the `kubeadm join ...` command printed above the lines detailing the `calico` configuration. This will be used to join child nodes to the cluster
    1. Run `watch kubectl get pods --all-namespaces` to show the list of system containers; wait until all containers are in the `Running` state (it should be around 9)
    1. Quit the `watch` and *optionally* run `kubectl taint nodes --all node-role.kubernetes.io/master-` to allow kubernetes to schedule pods on the master node
    1. Run `kubectl get nodes` and ensure the node is ready
1. On each child node:
    1. In the first terminal, run the `kubeadm join ...` command from above to join the node to the cluster
    1. Once the above command reaches the `[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...` line, run the `kubelet.sh` script in the second terminal
    1. Back on the master node, run the `watch kubectl get pods --all-namespaces` command again and wait for all containers to be in the `Running` state
    1. Run the `kubectl get nodes` command again and it should now show the new node in the cluster - **if you don't see the node here, make sure you set the hostname to a unique name**

## Caveats

- Since we are using `initramfs` for everything, we have to also specify that docker use a RAM filesystem, otherwise we will get errors (see [here](https://forums.docker.com/t/tinycore-8-0-x86-pivot-root-invalid-argument/32633) for more info).
- Requiring 4GB of RAM per node is not ideal, but if we reduce the amount of RAM things start to crash during the k8s initialization.
- Kubernetes is not supported on Alpine linux, which is why we have to run the `kubelet` command manually (k8s uses systemd by default, but Alpine uses OpenRC). See [here](https://bugs.alpinelinux.org/issues/10179) and [here](https://github.com/kubernetes/kubeadm/issues/1295).
- There are other network plugins available other than Calico, but I don't know enough about any of them to use a specific one. Calico had a nice tutorial, so I went with that.
- The `kubelet` arguments were taken from the [Arch Wiki](https://wiki.archlinux.org/index.php/Kubernetes), so there may be better arguments to use here.

## References
- [Docker RAMFS](https://forums.docker.com/t/tinycore-8-0-x86-pivot-root-invalid-argument/32633)
- [Calico Network Plugin w/ Instructions](https://docs.projectcalico.org/v3.7/getting-started/kubernetes/)
- [Arch Wiki Kubernetes Article](https://wiki.archlinux.org/index.php/Kubernetes)
- [Gentoo OpenRC service file for kubelet](https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-cluster/kubelet/files/kubelet.initd?id=2f0e00f22813902265b58ba37ad63daf0a1dc910)
- [Alpine Bug Tracker for Kubernetes Support](https://bugs.alpinelinux.org/issues/10179)
- [Kubernetes Bug Tracker for Alpine Support](https://github.com/kubernetes/kubeadm/issues/1295)
- [Example Kubernetes App Setup](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
- [Kubernetes Single-Master Setup](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
- [Random Alpine-k8s Vagrant Setup that could be useful at some point](https://github.com/davidmccormick/alpine-k8s)
