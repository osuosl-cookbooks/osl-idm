output "chef_zero" {
    value = openstack_networking_port_v2.chef_zero.all_fixed_ips.0
}
output "primary" {
    value = openstack_networking_port_v2.primary.all_fixed_ips.0
}
output "replica1" {
    value = openstack_networking_port_v2.replica1.all_fixed_ips.0
}
output "replica2" {
    value = openstack_networking_port_v2.replica2.all_fixed_ips.0
}
