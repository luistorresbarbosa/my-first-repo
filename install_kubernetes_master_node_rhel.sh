# Note: Execute on all nodes (master & worker)
# ensure ports [6443 10250] are open (using root)
firewall-cmd --add-port=6443/tcp
firewall-cmd --add-port=10250/tcp

# Disable Swap
swapoff -a
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# Disable SELinux
setenforce 0
sed -i 's/enforcing/disabled/g' /etc/selinux/config

# Download & Install - Docker | Kubelet | Kubeadm | Kubectl
# Note: Execute on all nodes (master & worker)

# Kubernetes Repository
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
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
yum update -y
yum install -y docker kubeadm kubelet kubectl --disableexcludes=kubernetes

# Start and enable docker and kubectl
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet

# For CentOS and RHEL
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl net.bridge.bridge-nf-call-iptables=1
sysctl net.ipv4.ip_forward=1
sysctl --system
echo "1" > /proc/sys/net/ipv4/ip_forward

# Restart the systemd daemon and the kubelet service with the commands:
systemctl daemon-reload
systemctl restart kubelet

# Initializing master node
kubeadm init --pod-network-cidr=10.240.0.0/16 > WorkerNodeJoinCommand.txt 

# If you want to run kubectl as "regular" user. Then, execute below.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Installing Flannel network-plug-in for cluster network
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
