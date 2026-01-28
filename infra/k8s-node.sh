#!/bin/bash

########################################
# Basic system prep
########################################

swapoff -a
modprobe overlay
modprobe br_netfilter
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sysctl --system
# Disable SELinux
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
systemctl disable firewalld --now || true

echo '(allow iptables_t cgroup_t (dir (ioctl)))' > /root/local_iptables.cil
semodule -i /root/local_iptables.cil
systemctl enable ocid.service
systemctl start ocid.service

echo "Waiting for OCI YUM endpoint..."
until curl -fs https://yum.us-ashburn-1.oci.oraclecloud.com >/dev/null; do
  sleep 3
done

########################################
# System update
########################################

dnf clean all
dnf update -y --skip-broken --nobest --allowerasing

#Add k8s repo
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
#Add docker repo for containerd
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

dnf install -y kubelet kubeadm cri-tools containerd.io --setopt=disable_excludes=kubernetes
cat <<'EOF' | tee /etc/containerd/config.toml
version = 3

[plugins]
  [plugins.'io.containerd.cri.v1.images']
    snapshotter = 'overlayfs'
    disable_snapshot_annotations = true
    discard_unpacked_layers = false
    max_concurrent_downloads = 3
    image_pull_progress_timeout = '5m0s'
    image_pull_with_sync_fs = false
    stats_collect_period = 10
    use_local_image_pull = false

    [plugins.'io.containerd.cri.v1.images'.pinned_images]
      sandbox = 'registry.k8s.io/pause:3.10.1'

    [plugins.'io.containerd.cri.v1.images'.registry]
      config_path = ''

    [plugins.'io.containerd.cri.v1.images'.image_decryption]
      key_model = 'node'

  [plugins.'io.containerd.cri.v1.runtime']
    enable_selinux = false
    selinux_category_range = 1024
    max_container_log_line_size = 16384
    disable_cgroup = false
    disable_apparmor = false
    restrict_oom_score_adj = false
    disable_proc_mount = false
    unset_seccomp_profile = ''
    tolerate_missing_hugetlb_controller = true
    disable_hugetlb_controller = true
    device_ownership_from_security_context = false
    ignore_image_defined_volumes = false
    netns_mounts_under_state_dir = false
    enable_unprivileged_ports = true
    enable_unprivileged_icmp = true
    enable_cdi = true
    cdi_spec_dirs = ['/etc/cdi', '/var/run/cdi']
    drain_exec_sync_io_timeout = '0s'
    ignore_deprecation_warnings = []
    stats_collect_period = '1s'
    stats_retention_period = '2m'

    [plugins.'io.containerd.cri.v1.runtime'.containerd]
      default_runtime_name = 'runc'
      ignore_blockio_not_enabled_errors = false
      ignore_rdt_not_enabled_errors = false

      [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes]
        [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc]
          runtime_type = 'io.containerd.runc.v2'
          runtime_path = ''
          pod_annotations = []
          container_annotations = []
          privileged_without_host_devices = false
          privileged_without_host_devices_all_devices_allowed = false
          cgroup_writable = false
          base_runtime_spec = ''
          cni_conf_dir = ''
          cni_max_conf_num = 0
          snapshotter = ''
          sandboxer = 'podsandbox'
          io_type = ''

          [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
            SystemdCgroup = true
            BinaryName = ''
            CriuImagePath = ''
            CriuWorkPath = ''
            IoGid = 0
            IoUid = 0
            NoNewKeyring = false
            Root = ''
            ShimCgroup = ''

    [plugins.'io.containerd.cri.v1.runtime'.cni]
      # DEPRECATED, use `bin_dirs` instead (since containerd v2.1).
      bin_dir = ''
      bin_dirs = ['/opt/cni/bin']
      conf_dir = '/etc/cni/net.d'
      max_conf_num = 1
      setup_serially = false
      conf_template = ''
      ip_pref = ''
      use_internal_loopback = false

  [plugins.'io.containerd.grpc.v1.cri']
    disable_tcp_service = true
    stream_server_address = '127.0.0.1'
    stream_server_port = '0'
    stream_idle_timeout = '4h0m0s'
    enable_tls_streaming = false

    [plugins.'io.containerd.grpc.v1.cri'.x509_key_pair_streaming]
      tls_cert_file = ''
      tls_key_file = ''
EOF

systemctl enable --now kubelet
systemctl restart containerd
PRIVATE_IP=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v1/vnics/ | jq -r '.[0].privateIp') 

echo "$PRIVATE_IP $(hostname)" | tee -a /etc/hosts