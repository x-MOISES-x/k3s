module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = ">=3.6.0"
  # general oci parameters
  compartment_id = var.compartment_ocid
  #label_prefix   = var.label_prefix
  freeform_tags = var.freeform_tags
  #defined_tags   = var.defined_tags
  # vcn parameters
  create_internet_gateway  = var.create_internet_gateway # boolean: true or false
  lockdown_default_seclist = "false"                     # boolean: true or false Needed for default Security Rules
  create_nat_gateway       = var.create_nat_gateway      # boolean: true or false
  create_service_gateway   = var.create_service_gateway  # boolean: true or false
  enable_ipv6              = var.enable_ipv6
  vcn_cidrs                = var.vcn_cidrs # List of IPv4 CIDRs
  vcn_dns_label            = var.vcn_dns_label
  vcn_name                 = var.vcn_name
  subnets                  = var.subnets
  # gateways parameters
  internet_gateway_display_name = var.internet_gateway_display_name
  #nat_gateway_display_name      = var.nat_gateway_display_name
  #service_gateway_display_name  = var.service_gateway_display_name
  attached_drg_id = var.attached_drg_id
}
