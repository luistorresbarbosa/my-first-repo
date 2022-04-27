sudo apt-get update -y
sudo apt-get install -y yum-utils device-mapper-persistent-data lvm2
sudo apt-get remove docker docker-engine docker.io containerd.io
sudo yum install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
