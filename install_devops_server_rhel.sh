# PRE-REQUIREMENTS >> sudo yum install WGET
# INSTALL DOCKER
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
sudo yum install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo mkdir -p /var/jenkins_home
sudo chown -R 1000:1000 /var/jenkins_home/

# INSTALL DOCKER-COMPOSE
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker-compose --version

# RUN DOCKER-COMPOSE UP
wget https://raw.githubusercontent.com/luistorresbarbosa/my-first-repo/master/docker-compose.yml
sleep 3
sudo docker-compose up
