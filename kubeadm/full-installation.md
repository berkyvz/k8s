# HA Kubernetes Cluster (Debian and CentOS based distrubitions)

## Docker Installation

1. Older versions of Docker were called docker, docker.io, or docker-engine. If these are installed, uninstall them:

__For Debian__
```
sudo apt-get remove docker docker-engine docker.io containerd runc
```
__For CentOS__
```
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

2. Install using the repository

- Before Start

__For Debian__
```
sudo apt-get update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release


curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg


echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

```
__For CentOS__
```
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

sudo yum install -y yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

3. Installation

__For Debian__
```
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

#To install spesific version
apt-cache madison docker-ce

For example: 5:18.09.1~3-0~debian-stretch

sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io

sudo systemctl enable docker
sudo systemctl enable containerd.service
sudo systemctl start docker
sudo systemctl start containerd.service

```
__For CentOS__
```
yum update

sudo yum install docker-ce docker-ce-cli containerd.io

# To choose specific version

yum list docker-ce --showduplicates | sort -r

For example: docker-ce-18.09.1

sudo yum install docker-ce-<VERSION_STRING> docker-ce-cli-<VERSION_STRING> containerd.io

sudo systemctl enable docker
sudo systemctl enable containerd.service
sudo systemctl start docker
sudo systemctl start containerd.service

```

4. Post Install to use docker as non-root user

```
sudo groupadd docker
sudo usermod -aG docker $USER

#Log out and log back in so that your group membership is re-evaluated.

newgrp docker 
```
---

## Install kubeadm, kubelet, kubectl

1. make sure required ports are available

- For Control-plane Nodes:

|Protocol|Direction|Port Range|Purpose|Used By|
|--- |--- |--- |--- |--- |
|TCP|Inbound|6443 |Kubernetes API server|All|
|TCP|Inbound|2379-2380|etcd server client API|kube-apiserver, etcd|
|TCP|Inbound|10250|kubelet API|Self, Control plane|
|TCP|Inbound|10251|kube-scheduler|Self|
|TCP|Inbound|10252|kube-controller-manager|Self|


- For Worker Nodes:

|Protocol|Direction|Port Range|Purpose|Used By|
|--- |--- |--- |--- |--- |
|TCP|Inbound|10250|kubelet API|Self, Control plane|
|TCP|Inbound|30000-32767|NodePort Services†|All|


2. Installation

__For CentOS__
```
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

swapoff -a; sed -i '/swap/d' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system


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


sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet

```

__For Debian__
```
sudo ufw disable

swapoff -a; sed -i '/swap/d' /etc/fstab

cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

```

## LoadBalancer step (HAProxy)


1. Installation

__For Debian__
```
sudo apt update
sudo apt-get install gcc tar make -y
sudo apt install -y haproxy
```

__For CentOS (Tar)__
```
sudo yum install gcc pcre-devel tar make -y
```
* Choose the version from http://www.haproxy.org/#down
```
wget http://www.haproxy.org/download/2.0/src/haproxy-2.0.7.tar.gz -O ~/haproxy.tar.gz

tar xzvf ~/haproxy.tar.gz -C ~/

cd ~/haproxy-<version>

make TARGET=linux-glibc

sudo make install

sudo mkdir -p /etc/haproxy

sudo mkdir -p /var/lib/haproxy 

sudo touch /var/lib/haproxy/stats

sudo ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy


sudo cp ~/haproxy-<version>/examples/haproxy.init /etc/init.d/haproxy

sudo chmod 755 /etc/init.d/haproxy

sudo systemctl daemon-reload

```

2. Append the below lines to `/etc/haproxy/haproxy.cfg`. Replace the <> tags before you update. You should add all master in backend configuration part as given below.

```
############## Configure HAProxy Frontend #############

frontend k8s-api-frontend

    bind <LOAD_BALANCER_SERVER_IP>:6443

    mode tcp
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }

    default_backend k8s-api-http

 

############## Configure HAProxy Backend #############

backend k8s-api-http

    balance roundrobin
    mode tcp
    option tcplog
    option tcp-check

    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

    server <master-1-hostname> <master-1-ip>:6443 check
    server <master-2-hostname> <master-2-ip>:6443 check
    server <master-3-hostname> <master-3-ip>:6443 check
```

```
sudo systemctl enable haproxy
sudo systemctl restart haproxy
```

## Cluster setup

```
kubeadm init --control-plane-endpoint="<load_balancer_ip>:6443" --upload-certs --apiserver-advertise-address=<current-node-ip> --pod-network-cidr=192.168.0.0/16
```

Adding another master
```

kubeadm init phase upload-certs --upload-certs

kubeadm token create  
--print-join-command 
--certificate-key *******
```

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

* Copy the commands to join other master nodes and worker nodes.

* Dont forget to add `--apiserver-advertise-address` for each join command if you are adding master node. This flag have to aim node ip address that you are currently adding.

---



## After Installation ( WeaveNet, Metric Server, Nginx Ingress)

You have to install CNI for networking (For more information https://www.weave.works/docs/net/latest/kubernetes/kube-addon/)

```
$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

```

1. Download Metric server yaml file (For newer versions check https://github.com/kubernetes-sigs/metrics-server)
```
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

2. Find the block in given below and add
```yaml
imagePullPolicy: Always
command:
 - /metrics-server
 - --kubelet-preferred-address-types=InternalIP
 - --kubelet-insecure-tls
```
 as command. 

- nano components.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        image: k8s.gcr.io/metrics-server/metrics-server:v0.5.0
        imagePullPolicy: IfNotPresent
        # HERE
        livenessProbe:

```

3. Apply
```
kubectl apply -f ./components.yaml
```

4. Setup Nginx ingress ( You can follow the link for more newer versions https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal)

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.46.0/deploy/static/provider/baremetal/deploy.yaml
```



---

## Common Kubeadm Init Errors Solutions

- `CGROUP_PID Error:` OracleLinux Kernel 4&4+ does not have `CGROUP_PID` in kernel. You should downgrade it to 3.**.
```
awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg
# find the correct kernel version and set it. After setting reboot vm.

For example:

Oracle Linux Server 7.1, with Linux 3.10.0-229.el7.x86_64 ( 0 )
Oracle Linux Server 7.1, with Unbreakable Enterprise Kernel 3.8.13-55.1.6.el7uek.x86_64 ( 1 )
Oracle Linux Server 7.1, with Linux 0-rescue-26ad0b77c2de4840ba8402282bdd9d17 ( 2 )

grub2-set-default <choose corrent one from the outputs above from starting index 0>

Like; grub2-set-default 2

grub2-mkconfig -o /etc/grub2.cfg

Now, check if `CGROUP_PID` is exist;

cat /boot/config-`uname -r` | grep CGROUP

```

* Check for more: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/

---
## Helper commands

- Getting new token

```
kubeadm token create --print-join-command

```

- Using spesific kubeconfig 
```
kubectl --kubeconfig=/etc/kubernetes/admin.conf

```

- Private registry

```
kubectl create secret docker-registry regcred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>

```

- Adding this ImagePullSecret to pod/deployment

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






