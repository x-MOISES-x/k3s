data "oci_core_subnet" "subnet1" {
  subnet_id = module.vcn.subnet_id["subnet1"]
}
# NSG for Instance Traffic starts here
resource "oci_core_network_security_group" "local" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = module.vcn.vcn_id
  #Optional
  display_name = "local traffic"
}
# Allow all traffic from subnet
resource "oci_core_network_security_group_security_rule" "local_ingress" {
  #Required
  network_security_group_id = oci_core_network_security_group.local.id
  #Optional
  direction   = "INGRESS"
  protocol    = "all"
  source      = data.oci_core_subnet.subnet1.cidr_block
  source_type = "CIDR_BLOCK"
  stateless   = false
}
# Allow all traffic from NLB NSG
resource "oci_core_network_security_group_security_rule" "local_ingress_from_nlb" {
  #Required
  network_security_group_id = oci_core_network_security_group.local.id
  #Optional
  direction   = "INGRESS"
  protocol    = "all"
  source_type = "NETWORK_SECURITY_GROUP"
  source      = oci_core_network_security_group.nlb.id
  stateless   = false
}

# Allow all traffic to internet
resource "oci_core_network_security_group_security_rule" "local_egress" {
  #Required
  network_security_group_id = oci_core_network_security_group.local.id
  #Optional
  direction   = "EGRESS"
  protocol    = "all"
  destination = "0.0.0.0/0"
}

# NSG for NLB Traffic starts here
resource "oci_core_network_security_group" "nlb" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = module.vcn.vcn_id
  #Optional
  display_name = "nlb traffic"
}
# Allow HTTP traffic from internet
resource "oci_core_network_security_group_security_rule" "nlb_http" {
  #Required
  network_security_group_id = oci_core_network_security_group.nlb.id
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
# Allow HTTPS traffic from internet
resource "oci_core_network_security_group_security_rule" "nlb_https" {
  #Required
  network_security_group_id = oci_core_network_security_group.nlb.id
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
# Allow all traffic from the Instance NSG
resource "oci_core_network_security_group_security_rule" "nlb_ingress" {
  #Required
  network_security_group_id = oci_core_network_security_group.nlb.id
  #Optional
  direction   = "INGRESS"
  protocol    = "all"
  source_type = "NETWORK_SECURITY_GROUP"
  source      = oci_core_network_security_group.local.id
  stateless   = false
}

# Allow all traffic to internet
resource "oci_core_network_security_group_security_rule" "nlb_internet" {
  #Required
  network_security_group_id = oci_core_network_security_group.nlb.id
  #Optional
  direction        = "EGRESS"
  protocol         = "all"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  stateless        = false
}
