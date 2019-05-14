#!/bin/ash

/usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
                 --kubeconfig=/etc/kubernetes/kubelet.conf \
                 --config=/var/lib/kubelet/config.yaml \
                 --network-plugin=cni
