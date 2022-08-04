# Pre-install wget before running this script > yum install wget -y && yum install net-tools -y
# Change the hostname by:
# sudo vi /etc/hostname
# sudo reboot
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

# Initialize the cluster
wget https://raw.githubusercontent.com/luistorresbarbosa/my-first-repo/master/kubeadm-config.yaml
kubeadm init --config kubeadm-config.yaml --ignore-preflight-errors=all > kubeadm-init-output.txt

# To start using your cluster, you need to run the following as a regular user:
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Weave net add-on
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# Open master required ports (Uncomment in case of firewalld needs to be active)
#firewall-cmd --add-port=6443/tcp --permanent
#firewall-cmd --add-port=2379/tcp --permanent
#firewall-cmd --add-port=2378/tcp --permanent
#firewall-cmd --add-port=10250/tcp --permanent
#firewall-cmd --add-port=10259/tcp --permanent
#firewall-cmd --add-port=10257/tcp --permanent

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml
