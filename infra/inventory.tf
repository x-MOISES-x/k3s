resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tftpl", {
    master = [for master in module.master.public_ip_all_attributes : master.ip_address]
    nodes  = [for node in module.nodes.public_ip_all_attributes : node.ip_address]
  })
  filename = "${path.module}/inventory.yaml"
}
