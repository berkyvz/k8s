```
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=10.9.1.211
```

```yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "10.9.1.216:6443"
networking:
  podSubnet: 192.168.0.0/16
```

```
kubeadm init --config=kubeadm-config.yaml --experimental-upload-certs
```

__Master / Worker join__
```

kubeadm join 10.9.1.216:6443 --token ****** --discovery-token-ca-cert-hash sha256:****** --control-plane --certificate-key ********

kubeadm join 10.9.1.216:6443 --token **** --discovery-token-ca-cert-hash sha256:******
```

__Adding master label__
```
kubectl label node mynode1 node-role.kubernetes.io/worker=
kubectl label node mynode2 node-role.kubernetes.io/worker=
```

```

kubeadm init phase upload-certs --upload-certs

kubeadm token create  
--print-join-command 
--certificate-key *******
```

__Links__
* https://github.com/justmeandopensource/kubernetes/tree/master/kubeadm-ha-multi-master
* https://www.weave.works/blog/weave-net-kubernetes-integration/
* https://octetz.com/docs/2019/2019-03-26-ha-control-plane-kubeadm/



