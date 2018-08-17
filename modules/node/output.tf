output "bastion_ssh_fqdn" {
    value = "${module.elb.this_elb_dns_name}"
}
