# Pre-install wget before running this script > yum install wget -y && yum install net-tools -y
# Change the hostname
# yum update to update the latest packages
yum update -y

# Install yum-utils
yum install -y yum-utils

# Disable swap
swapoff -a

# Changes to the IP tables
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Install Docker Engine
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install docker-ce docker-ce-cli containerd.io -y         

# Configure Docker Daemon
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Restart Docker and enable on boot
systemctl enable docker
systemctl daemon-reload
systemctl restart docker

# Installing Kubelet | Kubeadm | Kubectl
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

# Solve containerd conflicts
yes | rm /etc/containerd/config.toml
systemctl restart containerd

# Disable firewall
systemctl stop firewalld
systemctl disable firewalld

# Open worker required ports (uncomment if firewalld must be active)
#firewall-cmd --add-port=10250/tcp --permanent
#firewall-cmd --add-port=30000-32767/tcp --permanent

## Run Kubernetes join cmd
