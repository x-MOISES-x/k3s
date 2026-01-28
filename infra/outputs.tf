output "instance_id" {
  value = module.master.instance_id
}
output "public_ips" {
  value = {
    master = [for master in module.master.public_ip_all_attributes : master.ip_address]
    nodes  = [for node in module.nodes.public_ip_all_attributes : node.ip_address]
  }
}
output "nlb_ip" {
  value = oci_network_load_balancer_network_load_balancer.nlb.ip_addresses
}
