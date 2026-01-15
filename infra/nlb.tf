resource "oci_network_load_balancer_network_load_balancer" "k3s_nlb" {
  compartment_id                 = var.compartment_ocid
  display_name                   = "k3s-nlb"
  subnet_id                      = data.oci_core_subnet.subnet1.id # Must be in a Public Subnet
  is_private                     = false
  is_preserve_source_destination = false
  network_security_group_ids     = [oci_core_network_security_group.k3s_nlb.id]
}

resource "oci_network_load_balancer_backend_set" "k3s_backend_set" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  name                     = "k3s-backend-set"
  health_checker {
    protocol           = "TCP"
    port               = 80
    interval_in_millis = 10000
    retries            = 3
  }
  policy             = "FIVE_TUPLE" # Uses IP+Port hashing for better distribution
  is_preserve_source = false
}

resource "oci_network_load_balancer_backend" "k3s_master" {
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  target_id                = module.master.instance_id[0]
  port                     = 80
}

resource "oci_network_load_balancer_backend" "k3s_node_1" {
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  target_id                = module.nodes.instance_id[0]
  port                     = 80
}

resource "oci_network_load_balancer_backend" "k3s_node_2" {
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  target_id                = module.nodes.instance_id[1]
  port                     = 80
}

resource "oci_network_load_balancer_backend" "k3s_node_3" {
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  target_id                = module.nodes.instance_id[2]
  port                     = 80
}

resource "oci_network_load_balancer_listener" "http_listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_backend_set.name
  name                     = "k3s-http-listener"
  protocol                 = "TCP"
  port                     = 80
}

//resource "oci_network_load_balancer_listener" "https_listener" {
//  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
//  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_backend_set.name
//  name                     = "k3s-https-listener"
//  protocol                 = "TCP"
//  port                     = 443
//}
