#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/k3s-userdata.log) 2>&1

echo "=== K3s OCI cloud-init bootstrap starting ==="

########################################
# Basic system prep
########################################

swapoff -a

systemctl enable ocid.service
systemctl start ocid.service

systemctl disable firewalld --now || true


########################################
# Wait for OCI YUM service
########################################
export OPC=/home/opc
cat <<'EOF' > $OPC/k3s-server.sh
#!/bin/bash
PRIVATE_IP=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v1/vnics/ | jq -r '.[0].privateIp') 
echo $PRIVATE_IP
K3S_TOKEN="${K3S_TOKEN:-$(openssl rand -hex 32)}"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --flannel-backend none --disable-kube-proxy --disable-network-policy --node-ip $PRIVATE_IP --token $K3S_TOKEN --cluster-init --selinux --write-kubeconfig-mode 644" sh -s -
mkdir -p $HOME/.kube 
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config 

CLI_ARCH=amd64 
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
echo "Installing Cilium CLI version $CILIUM_CLI_VERSION for $CLI_ARCH..."
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum 
sudo tar -xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
cilium install --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" --set k8sServiceHost="${PRIVATE_IP}" --set k8sServicePort="6443"

echo $PRIVATE_IP
SERVER_TOKEN="$(sudo cat /var/lib/rancher/k3s/server/node-token)"
echo $SERVER_TOKEN
EOF

chmod +x $OPC/k3s-server.sh

echo "Waiting for OCI YUM endpoint..."
until curl -fs https://yum.us-ashburn-1.oci.oraclecloud.com >/dev/null; do
  sleep 3
done

########################################
# System update
########################################

dnf clean all
dnf update -y




