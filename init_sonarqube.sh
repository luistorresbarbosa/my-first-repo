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
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind
