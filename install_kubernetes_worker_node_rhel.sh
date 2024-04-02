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
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Disable swap
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# Solve containerd conflicts
rm /etc/containerd/config.toml
systemctl restart containerd

# Kubernetes Repository
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

# Install Kubernetes
sudo dnf install -y yum-utils
sudo dnf update kubectl
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

# Execute control plane Join Command 
