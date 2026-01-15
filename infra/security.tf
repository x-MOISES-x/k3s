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
  direction   = "INGRESS"
  protocol    = "all"
  source      = data.oci_core_subnet.subnet1.cidr_block
  source_type = "CIDR_BLOCK"
  stateless   = false
}

resource "oci_core_network_security_group_security_rule" "k3s_local_ingress_from_nlb" {
  #Required
  network_security_group_id = oci_core_network_security_group.k3s_local.id
  #Optional
  direction   = "INGRESS"
  protocol    = "all"
  source_type = "NETWORK_SECURITY_GROUP"
  source      = oci_core_network_security_group.k3s_nlb.id
  stateless   = false
}


resource "oci_core_network_security_group_security_rule" "k3s_local_egress" {
  #Required
  network_security_group_id = oci_core_network_security_group.k3s_local.id
  #Optional
  direction   = "EGRESS"
  protocol    = "all"
  destination = "0.0.0.0/0"
}

resource "oci_core_network_security_group" "k3s_nlb" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = module.vcn.vcn_id
  #Optional
  display_name = "k3s nlb traffic"
}
resource "oci_core_network_security_group_security_rule" "k3s_nlb_http" {
  #Required
  network_security_group_id = oci_core_network_security_group.k3s_nlb.id
  #Optional
  direction = "INGRESS"
  protocol  = "6" //tcp
  source    = "0.0.0.0/0"
  stateless = false
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}
resource "oci_core_network_security_group_security_rule" "k3s_nlb_https" {
  #Required
  network_security_group_id = oci_core_network_security_group.k3s_nlb.id
  #Optional
  direction = "INGRESS"
  protocol  = "6" //tcp
  source    = "0.0.0.0/0"
  stateless = false
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "k3s_nlb_ingress" {
  #Required
  network_security_group_id = oci_core_network_security_group.k3s_nlb.id
  #Optional
  direction   = "INGRESS"
  protocol    = "all"
  source_type = "NETWORK_SECURITY_GROUP"
  source      = oci_core_network_security_group.k3s_local.id
  stateless   = false
}

resource "oci_core_network_security_group_security_rule" "k3s_nlb_internet" {
  #Required
  network_security_group_id = oci_core_network_security_group.k3s_nlb.id
  #Optional
  direction   = "EGRESS"
  protocol    = "all"
  destination = "0.0.0.0/0"
}
