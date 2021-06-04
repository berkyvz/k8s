## Before


* Kill the firewall `ufw disable`
* Disable the swap `swapoff -a; sed -i '/swap/d' /etc/fstab`

optional:
```
"lsmod | grep br_netfilter", "modprobe br_netfilter", "swapoff -a" ve "sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
```

* Selinux permissive `setenforce 0` and `sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config"`
* Update sysctl settings for k8s
```
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
```


## Installing Kubelet, Kubeadm, Kubectl

__For Debian__
```
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg


echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

__For RHEL__
```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet
```

## Init Cluster

```
kubeadm init --control-plane-endpoint="172.16.16.100:6443" --upload-certs --apiserver-advertise-address=172.16.16.101 --pod-network-cidr=192.168.0.0/16
```

* control-plane-endpoint : load balancer endpoing (example HAProxy server)
*  apiserver-advertise-address : active network interface (example eth1)

## Second Control Plane Node

You need some command below. Dont forget to add `--apiserver-advertise-address` to this control plain.

```
kubeadm join loadBalancerIP:6443 --token xxxx --discovery-token-ca-cert-hash sha256:xxxx --control-plane --certificate-key xxxx
```

Getting new token:
```
kubeadm token create --print-join-command

```

## Using Admin Conf
kubectl --kubeconfig=/etc/kubernetes/admin.conf

## Private Registry
Create a Secret by providing credentials on the command line 
```
kubectl create secret docker-registry regcred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```
__Adding this ImagePullSecret to pod/deployment__
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-reg
spec:
  containers:
  - name: private-reg-container
    image: <your-private-image>
  imagePullSecrets:
  - name: regcred
  ```

