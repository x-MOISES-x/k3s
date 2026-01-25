locals {
  ssh_key = sensitive(file(var.ssh_authorized_keys_path))
}

data "oci_core_images" "images_for_shape" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

module "master" {
  source                      = "oracle-terraform-modules/compute-instance/oci"
  instance_count              = 1    # how many instances do you want?
  ad_number                   = null # AD number to provision instances. If null, instances are provisionned in a rolling manner starting with AD1
  compartment_ocid            = var.compartment_ocid
  instance_display_name       = "k3s-master"
  instance_flex_memory_in_gbs = 6
  instance_flex_ocpus         = 1
  source_ocid                 = data.oci_core_images.images_for_shape.images[0].id
  subnet_ocids                = [module.vcn.subnet_id["subnet1"]]
  public_ip                   = "EPHEMERAL" # NONE, RESERVED or EPHEMERAL
  ssh_public_keys             = local.ssh_key
  user_data                   = base64encode(file("k3s-master.sh"))
  shape                       = var.shape
  instance_state              = var.instance_state # RUNNING or STOPPED
  boot_volume_backup_policy   = "disabled"         # disabled, gold, silver or bronze
  cloud_agent_plugins         = { "autonomous_linux" : "ENABLED", "bastion" : "DISABLED", "block_volume_mgmt" : "DISABLED", "custom_logs" : "DISABLED", "java_management_service" : "DISABLED", "management" : "DISABLED", "monitoring" : "ENABLED", "osms" : "DISABLED", "run_command" : "DISABLED", "vulnerability_scanning" : "DISABLED" }
  primary_vnic_nsg_ids        = [oci_core_network_security_group.k3s_local.id]
}

module "nodes" {
  source                      = "oracle-terraform-modules/compute-instance/oci"
  instance_count              = 3    # how many instances do you want?
  ad_number                   = null # AD number to provision instances. If null, instances are provisionned in a rolling manner starting with AD1
  compartment_ocid            = var.compartment_ocid
  instance_display_name       = "k3s-node"
  instance_flex_memory_in_gbs = 6
  instance_flex_ocpus         = 1
  source_ocid                 = data.oci_core_images.images_for_shape.images[0].id
  subnet_ocids                = [module.vcn.subnet_id["subnet1"]]
  public_ip                   = "EPHEMERAL" # NONE, RESERVED or EPHEMERAL
  ssh_public_keys             = local.ssh_key
  user_data                   = base64encode(file("k3s-node.sh"))
  shape                       = var.shape
  instance_state              = var.instance_state # RUNNING or STOPPED
  boot_volume_backup_policy   = "disabled"         # disabled, gold, silver or bronze
  cloud_agent_plugins         = { "autonomous_linux" : "ENABLED", "bastion" : "DISABLED", "block_volume_mgmt" : "DISABLED", "custom_logs" : "DISABLED", "java_management_service" : "DISABLED", "management" : "DISABLED", "monitoring" : "ENABLED", "osms" : "DISABLED", "run_command" : "DISABLED", "vulnerability_scanning" : "DISABLED" }
  primary_vnic_nsg_ids        = [oci_core_network_security_group.k3s_local.id]
}
