resource "oci_network_load_balancer_network_load_balancer" "nlb" {
  compartment_id                 = var.compartment_ocid
  display_name                   = "nlb"
  subnet_id                      = data.oci_core_subnet.subnet1.id # Must be in a Public Subnet
  is_private                     = false
  is_preserve_source_destination = false
  network_security_group_ids     = [oci_core_network_security_group.k3s_nlb.id]
  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
  }
}

resource "oci_network_load_balancer_backend_set" "http_backend_set" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  name                     = "http-backend-set"
  health_checker {
    protocol           = "TCP"
    port               = 80
    interval_in_millis = 10000
    retries            = 5
  }
  policy             = "FIVE_TUPLE" # Uses IP+Port hashing for better distribution
  is_preserve_source = false
}

resource "oci_network_load_balancer_backend_set" "https_backend_set" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  name                     = "https-backend-set"
  health_checker {
    protocol           = "TCP"
    port               = 443
    interval_in_millis = 10000
    retries            = 5
  }
  policy             = "FIVE_TUPLE" # Uses IP+Port hashing for better distribution
  is_preserve_source = false
}

data "oci_core_instance" "master" {
  count       = length(module.master.instance_id)
  instance_id = module.master.instance_id[count.index]
}

data "oci_core_instance" "node" {
  count       = length(module.nodes.instance_id)
  instance_id = module.nodes.instance_id[count.index]
}

resource "oci_network_load_balancer_backend" "master_http" {
  depends_on               = [oci_network_load_balancer_listener.http_listener]
  count                    = length(data.oci_core_instance.master)
  backend_set_name         = oci_network_load_balancer_backend_set.http_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  target_id                = module.master.instance_id[count.index]
  port                     = 80
}


resource "oci_network_load_balancer_backend" "node_http" {
  depends_on               = [oci_network_load_balancer_listener.http_listener]
  count                    = length(data.oci_core_instance.node)
  backend_set_name         = oci_network_load_balancer_backend_set.http_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  target_id                = module.nodes.instance_id[count.index]
  port                     = 80
}

resource "oci_network_load_balancer_listener" "http_listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_http_backend_set.name
  name                     = "http-listener"
  protocol                 = "TCP"
  port                     = 80
}

resource "oci_network_load_balancer_backend" "master_https" {
  depends_on               = [oci_network_load_balancer_listener.https_listener]
  count                    = length(data.oci_core_instance.master)
  backend_set_name         = oci_network_load_balancer_backend_set.https_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  target_id                = module.master.instance_id[count.index]
  port                     = 443
}

resource "oci_network_load_balancer_backend" "node_https" {
  depends_on               = [oci_network_load_balancer_listener.https_listener]
  count                    = length(data.oci_core_instance.node)
  backend_set_name         = oci_network_load_balancer_backend_set.https_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  target_id                = module.nodes.instance_id[count.index]
  port                     = 443
}

resource "oci_network_load_balancer_listener" "https_listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  default_backend_set_name = oci_network_load_balancer_backend_set.https_backend_set.name
  name                     = "https-listener"
  protocol                 = "TCP"
  port                     = 443
}

output "nlb_ip" {
  value = oci_network_load_balancer_network_load_balancer.nlb.ip_addresses
}
