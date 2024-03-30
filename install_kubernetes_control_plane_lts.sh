#!/bin/bash
# IMPORTANT: Before runing this script please 
# Edit the hostname: vi /etc/hostname
# install wget: yum install wget -y && yum install net-tools -y 

# Update system packages
sudo dnf update -y

# Prepare blank LXC container for Kubernetes
sudo cat <<EOF > /etc/rc.local
if [ ! -e /dev/kmsg ]; then
ln -s /dev/console /dev/kmsg
fi
EOF
chmod +x /etc/rc.local

# Note: Execute on all nodes (master & worker)
# ensure ports [6443 10250] are open (using root)
sudo yum install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --add-port=6443/tcp
sudo firewall-cmd --add-port=10250/tcp

# Download & Install - Docker
sudo yum check-update
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Disable swap
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# Solve containerd conflicts
rm /etc/containerd/config.toml
systemctl restart containerd

# Install Kubernetes
sudo dnf install -y yum-utils
sudo dnf config-manager --add-repo https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# For CentOS and RHEL
sudo cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo sysctl net.ipv4.ip_forward=1
sudo sysctl --system
echo "1" > /proc/sys/net/ipv4/ip_forward

# Configure sysctl
sudo modprobe br_netfilter
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sudo echo '1' > /proc/sys/net/ipv4/ip_forward
sudo sysctl -p

# Initialize Kubernetes
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 > ControlPlaneNodeLog.txt 

# Setup kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel networking
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Allow scheduling on the master node
kubectl taint nodes --all node-role.kubernetes.io/master-
