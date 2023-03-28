## On the DEVOPS machine run the following:
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192

## Enter the Jenkins container:
docker exec -it -u root installation_scripts_jenkins_1 /bin/bash

## On the jenkins container install envsubt:
apt-get update
apt-get install gettext-base
## On the jenkins container install kubectl:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
