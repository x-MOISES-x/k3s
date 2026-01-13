output "instance_id" {
  value = module.master.instance_id
}
output "public_ips" {
  value = {
    master = module.master.public_ip_all_attributes[0].ip_address
    nodes  = [module.nodes.public_ip_all_attributes[0].ip_address, module.nodes.public_ip_all_attributes[1].ip_address, module.nodes.public_ip_all_attributes[2].ip_address]
  }
}
output "nlb_ip" {
  value = oci_network_load_balancer_network_load_balancer.k3s_nlb.ip_addresses
}
