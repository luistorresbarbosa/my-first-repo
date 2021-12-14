sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf repolist -v
dnf list docker-ce --showduplicates | sort -r
sudo dnf install docker-ce --nobest
systemctl status docker
sudo usermod -aG docker $USER
id $USER
sudo systemctl disable firewalld
docker pull alpine