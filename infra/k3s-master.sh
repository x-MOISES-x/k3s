#!/bin/bash

########################################
# Basic system prep
########################################

swapoff -a

systemctl enable ocid.service
systemctl start ocid.service

systemctl disable firewalld --now || true

echo '(allow iptables_t cgroup_t (dir (ioctl)))' > /root/local_iptables.cil
semodule -i /root/local_iptables.cil

########################################
# Wait for OCI YUM service
########################################
export OPC=/home/opc
cat <<'EOF' > $OPC/k3s-server.sh
#!/bin/bash
PRIVATE_IP=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v1/vnics/ | jq -r '.[0].privateIp') 
echo $PRIVATE_IP
K3S_TOKEN="${K3S_TOKEN:-$(openssl rand -hex 32)}"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --flannel-backend none --disable traefik --disable-kube-proxy --disable-network-policy --node-ip $PRIVATE_IP --token $K3S_TOKEN --cluster-init --selinux --write-kubeconfig-mode 644" sh -s -
mkdir -p $HOME/.kube 
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config 


kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml


CLI_ARCH=amd64 
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
echo "Installing Cilium CLI version $CILIUM_CLI_VERSION for $CLI_ARCH..."
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum 
sudo tar -xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
cilium install --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" --set k8sServiceHost="${PRIVATE_IP}" --set k8sServicePort="6443" --set gatewayAPI.enabled="true" --set envoyConfig.enabled="true" --set loadBalancer.l7.backend="envoy" --set nodeIPAM.enabled="true" --set defaultLBserviceipam="none"



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
dnf update -y --skip-broken --nobest --allowerasing




