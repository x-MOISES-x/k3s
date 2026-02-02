#!/bin/bash

########################################
# Basic system prep
########################################

swapoff -a
sed -i.bak '/^\/.swapfile/d' /etc/fstab
systemctl enable ocid.service
systemctl start ocid.service
systemctl disable firewalld --now || true

########################################
# Wait for OCI YUM service
########################################

sudo mkdir -p /mnt/shared
sudo chown opc:opc /mnt/shared
echo '/mnt/shared 10.0.1.0/24(rw,sync,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports > /dev/null
sudo exportfs -a
sudo systemctl restart nfs-server
sudo systemctl enable nfs-server

echo "Waiting for OCI YUM endpoint..."
until curl -fs https://yum.us-ashburn-1.oci.oraclecloud.com >/dev/null; do
  sleep 3
done

########################################
# System update
########################################

dnf clean all
dnf update -y --skip-broken --nobest --allowerasing

export OPC=/home/opc
PRIVATE_IP=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v1/vnics/ | jq -r '.[0].privateIp') 
K3S_TOKEN="${K3S_TOKEN:-$(openssl rand -hex 32)}"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --flannel-backend none --disable traefik --disable-kube-proxy --disable-network-policy --node-ip $PRIVATE_IP --token $K3S_TOKEN --cluster-init --selinux --write-kubeconfig-mode 644" sh -s -
mkdir -p $OPC/.kube 
sudo cp /etc/rancher/k3s/k3s.yaml $OPC/.kube/config
chown opc:opc $OPC/.kube/config 

curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.12.1/deploy/install-driver.sh | bash -s v4.12.1 --
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml

export KUBECONFIG=/home/opc/.kube/config
CLI_ARCH=amd64 
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
echo "Installing Cilium CLI version $CILIUM_CLI_VERSION for $CLI_ARCH..."
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum 
sudo tar -xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
cilium install --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" --set k8sServiceHost="${PRIVATE_IP}" --set k8sServicePort="6443" --set gatewayAPI.enabled="true" --set envoyConfig.enabled="true" --set loadBalancer.l7.backend="envoy" --set nodeIPAM.enabled="true" --set defaultLBServiceIPAM="nodeipam" --set kubeProxyReplacement="true"

wget https://get.helm.sh/helm-v4.0.5-linux-arm64.tar.gz
tar -zxvf helm-v4.0.5-linux-arm64.tar.gz
sudo mv linux-arm64/helm /usr/local/bin/helm
rm -rf linux-arm64
rm helm-v4.0.5-linux-arm64.tar.gz

openssl req -x509 -newkey rsa:4096 -keyout this.key -out this.crt -days 365 -nodes -subj "/CN=k3s.local"
kubectl create secret tls ssk3s --cert=this.crt --key=this.key -n cilium-secrets

echo "$PRIVATE_IP $(hostname)" | tee -a /etc/hosts
echo $PRIVATE_IP
SERVER_TOKEN="$(sudo cat /var/lib/rancher/k3s/server/node-token)"
echo $SERVER_TOKEN



