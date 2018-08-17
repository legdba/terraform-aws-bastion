
provider "aws" {
  version    = "~> 1.30"
  region     = "${var.region}"
}

module "vpc" {
    source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=f7a874cb2c74815d301608c3fe6eadf02cc57be5" # v1.37.0

    name                    = "${var.stack_id}"
    cidr                    = "${var.cidr_ipv4}"
    azs                     = "${var.azs}"
    public_subnets          = "${var.subnets_ipv4}"
    map_public_ip_on_launch = true

    tags     = "${local.tags}"
    vpc_tags = {
        Name = "${var.stack_id}"
    }
}
