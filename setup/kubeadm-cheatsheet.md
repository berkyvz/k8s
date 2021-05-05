sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=10.9.1.211

apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "10.9.1.216:6443"
networking:
  podSubnet: 192.168.0.0/16

kubeadm init --config=kubeadm-config.yaml --experimental-upload-certs

https://www.weave.works/blog/weave-net-kubernetes-integration/

kubeadm join 10.9.1.216:6443 --token 9y3vhg.rej0yz7ch3qhs8ug --discovery-token-ca-cert-hash sha256:1fdaf9013cb14f4693222cffcbb9f47892eb4782a81d7ad9304d69db4304a55d --control-plane --certificate-key 259f5168dc6b352214cc89e13da45b5a8143191f42719997551bd0986c31e042

kubeadm join 10.9.1.216:6443 --token 9y3vhg.rej0yz7ch3qhs8ug --discovery-token-ca-cert-hash sha256:1fdaf9013cb14f4693222cffcbb9f47892eb4782a81d7ad9304d69db4304a55d


kubectl label node anketnode1 node-role.kubernetes.io/worker=
kubectl label node anketnode2 node-role.kubernetes.io/worker=


kubeadm init phase upload-certs --upload-certs

kubeadm token create  
--print-join-command 
--certificate-key 1da66bdf71f9493daf38ac2e8980c51a018bc52f457db7336649c862ef7284c2



NODE2:

kubeadm join 10.9.1.211:6443 --token e23rkr.wfgt5gupzxxsg6ky     
--discovery-token-ca-cert-hash sha256:f85c238478df24d0db2d3dc212ed40b75a682534639d7e7671c2cfcff385c2ec 
--experimental-control-plane --certificate-key 1da66bdf71f9493daf38ac2e8980c51a018bc52f457db7336649c862ef7284c2


https://octetz.com/docs/2019/2019-03-26-ha-control-plane-kubeadm/
