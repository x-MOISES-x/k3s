data "oci_core_subnet" "subnet1" {
  subnet_id = module.vcn.subnet_id["subnet1"]
}

resource "oci_core_network_security_group" "k3s_local" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = module.vcn.vcn_id
  #Optional
  display_name = "k3s local traffic"
}

resource "oci_core_network_security_group_security_rule" "k3s_local_ingress" {
  #Required
  network_security_group_id = oci_core_network_security_group.k3s_local.id
  #Optional
  direction = "INGRESS"
  protocol  = "all"
  source    = data.oci_core_subnet.subnet1.cidr_block
}

resource "oci_core_network_security_group_security_rule" "k3s_local_egress" {
  #Required
  network_security_group_id = oci_core_network_security_group.k3s_local.id
  #Optional
  direction   = "EGRESS"
  protocol    = "all"
  destination = "0.0.0.0/0"
}
