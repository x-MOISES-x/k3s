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
