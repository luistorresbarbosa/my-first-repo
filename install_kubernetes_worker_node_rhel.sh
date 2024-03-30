#!/bin/bash
# IMPORTANT: Before runing this script please 
# Edit the hostname: vi /etc/hostname
# install wget: yum install wget -y && yum install net-tools -y 

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

# Disable Swap - uncomment if not a LXC container
# swapoff -a
# sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# Disable SELinux
sudo setenforce 
#uncomment line below if not a LXC container
#sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config

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

# In order to address the error (dial tcp 127.0.0.1:10248: connect: connection refused.), run the following:
# sudo mkdir /etc/docker
# cat <<EOF | sudo tee /etc/docker/daemon.json
# {
#   "exec-opts": ["native.cgroupdriver=systemd"],
#   "log-driver": "json-file",
#   "log-opts": {
#     "max-size": "100m"
#   },
#   "storage-driver": "overlay2"
# }
# EOF

# Download & Install - Docker | Kubelet | Kubeadm | Kubectl
# Note: Execute on all nodes (master & worker)

# Start and enable docker and kubectl
sudo systemctl enable docker && systemctl start docker

# Kubernetes Repository
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOFF

# Install Kubernetes
sudo dnf install -y yum-utils
sudo dnf update kubectl
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet
systemctl start kubelet

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

# Solve containerd conflicts
rm /etc/containerd/config.toml
systemctl restart containerd

# If you want to run kubectl as "regular" user. Then, execute below.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Installing Flannel network-plug-in for cluster network
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
