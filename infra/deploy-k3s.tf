resource "null_resource" "ansible" {
  depends_on = [local_file.ansible_inventory, oci_network_load_balancer_backend.k3s_master_http, oci_network_load_balancer_backend.k3s_master_https]
  provisioner "local-exec" {
    command = "ansible master -i inventory.yaml -u opc -m shell -a '/home/opc/k3s-server.sh'"
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
}
