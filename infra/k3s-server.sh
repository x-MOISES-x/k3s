#!/bin/bash
sudo swapoff -a
sudo systemctl enable ocid.service
sudo systemctl start ocid.service
sudo systemctl disable firewalld --now
echo "Waiting for internet..."
while ! ping -c 1 -W 1 google.com; do sleep 2; done
sudo dnf update -y
PRIVATE_IP=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v1/vnics/ | jq -r '.[0].privateIp') 
PUBLIC_IP=$(curl -s ifconfig.me)
echo $PUBLIC_IP
K3S_TOKEN="${K3S_TOKEN:-$(openssl rand -hex 32)}"
echo $K3S_TOKEN 
curl -sfL https://get.k3s.io | sh -s - --flannel-backend none --disable-network-policy --tls-san $PUBLIC_IP --node-ip $PRIVATE_IP --token $K3S_TOKEN
OPC=/home/opc 
mkdir -p $OPC/.kube
sleep 30 
sudo cp /etc/rancher/k3s/k3s.yaml $OPC/.kube/config 
sudo sed -i "s/127.0.0.1/$PUBLIC_IP/g" $OPC/.kube/config 
sudo chown -R opc:opc $OPC/.kube
echo "export KUBECONFIG=$OPC/.kube/config" >> $OPC/.bashrc 
export KUBECONFIG=$OPC/.kube/config
CLI_ARCH=amd64 
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
echo "Installing Cilium CLI version $CILIUM_CLI_VERSION for $CLI_ARCH..."
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum 
sudo tar -xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
cilium install --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16"
