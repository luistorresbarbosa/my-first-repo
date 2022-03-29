# Note: Execute on all nodes (master & worker)
# ensure ports [6443 10250] are open (using root)
sudo firewall-cmd --add-port=6443/tcp
sudo firewall-cmd --add-port=10250/tcp

# Disable Swap
sudo swapoff -a
sudo sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# Disable SELinux
sudo setenforce 0
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config

# Download & Install - Docker | Kubelet | Kubeadm | Kubectl
# Note: Execute on all nodes (master & worker)

# Kubernetes Repository
sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

# Installing Docker | Kubelet | Kubeadm | Kubectl
sudo yum update -y
sudo yum install -y docker kubeadm kubelet kubectl --disableexcludes=kubernetes

# Start and enable docker and kubectl
sudo systemctl enable docker && systemctl start docker
sudo systemctl enable kubelet && systemctl start kubelet

# For CentOS and RHEL
sudo cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo sysctl net.ipv4.ip_forward=1
sudo sysctl --system
echo "1" > /proc/sys/net/ipv4/ip_forward

# Restart the systemd daemon and the kubelet service with the commands:
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Initializing master node
kubeadm init --pod-network-cidr=10.240.0.0/16 > WorkerNodeJoinCommand.txt 

# If you want to run kubectl as "regular" user. Then, execute below.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Installing Flannel network-plug-in for cluster network
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
