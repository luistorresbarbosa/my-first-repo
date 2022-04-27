sudo apt-get update -y
sudo apt-get install -y device-mapper-persistent-data lvm2
sudo apt-get remove docker docker-engine docker.io
sudo apt-get install docker.io
sudo systemctl start docker
