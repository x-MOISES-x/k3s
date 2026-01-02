output "instance_id" {
    value = module.instance.instance_id
}
output "public_ips" {
    value = module.instance.public_ip_all_attributes
}
