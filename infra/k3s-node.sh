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


echo "Waiting for OCI YUM endpoint..."
until curl -fs https://yum.us-ashburn-1.oci.oraclecloud.com >/dev/null; do
  sleep 3
done

########################################
# System update
########################################

dnf clean all
dnf update -y

OPC=/home
cat <<EOF > $OPC/k3s-agent.sh
#!/bin/bash
PRIVATE_IP=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v1/vnics/ | jq -r '.[0].privateIp') 
read -p "Enter the server IP: " SERVER_IP
read -p "Enter the server token: " SERVER_TOKEN
curl -sfL https://get.k3s.io | K3S_URL=https://$SERVER_IP:6443 K3S_TOKEN=$SERVER_TOKEN INSTALL_K3S_EXEC="agent --node-ip $PRIVATE_IP --selinux" sh -
EOF

chmod +x $OPC/k3s-agent.sh


