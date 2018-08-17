provider "aws" {
  version    = "~> 1.30"
  region     = "${var.region}"
}

provider "null" {
  version    = "~> 1.0"
}

provider "random" {
  version    = "~> 1.3"
}

provider "template" {
  version    = "~> 1.0"
}

###
# Data sources
###
data "aws_ami" "bastion_latest" {
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }
  owners = ["${var.ami_owner}"]
}

data "aws_vpc" "bastion" {
  cidr_block = "${var.cidr_ipv4}"
  # TODO: filter on same-env tag
  # tags = {
  #   Stack = "${var.stack_id}"
  # }
}

data "aws_subnet_ids" "bastion" {
  vpc_id = "${data.aws_vpc.bastion.id}"
  # TODO: filter on same-env tag
  # tags = {
  #   Stack = "${var.stack_id}"
  # }
}

data "aws_iam_role" "bastion" {
  name = "${var.role}"
}

###
# Instance profile for attaching role to the ASG
# FIXME: IAM resources should not be modified here; but so far a data iam_instance_profile fails wit ha weird error.
###
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.role}_profile_${var.stack_id}" # instance profile names shall be globally unique -> add a prefix until the fix-me gets fixed.
  role = "${data.aws_iam_role.bastion.name}"
}

###
# Security Group(s)
###
module "sg_ssh" {
    source = "github.com/terraform-aws-modules/terraform-aws-security-group//modules/ssh?ref=v2.1.0"

    name                = "ssh-to-bastion"
    description         = "Security group for bastion to be SSHed into"
    vpc_id              = "${data.aws_vpc.bastion.id}"
    ingress_cidr_blocks = ["0.0.0.0/0"]

    tags = "${local.tags}"
}

###
# ASG
###
# FIXME: ensure existing instance(s) are re-created upon major ASG changes, say AMI or role; see such as AMI) cause exitsing instances t obe re-created. (https://stackoverflow.com/questions/39345609/how-to-recreate-ec2-instances-of-an-autoscaling-group-with-terraform
module "asg" {
  source = "github.com/terraform-aws-modules/terraform-aws-autoscaling?ref=v2.7.0"

  name                 = "bastion-${var.stack_id}"
  lc_name              = "bastion-${var.stack_id}"
  image_id             = "${data.aws_ami.bastion_latest.id}"
  key_name             = "${var.keypair_name}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${module.sg_ssh.this_security_group_id}"]
  iam_instance_profile = "${aws_iam_instance_profile.bastion.id}"

#   ebs_block_device = [
#     {
#       device_name           = "/dev/xvdz"
#       volume_type           = "gp2"
#       volume_size           = "50"
#       delete_on_termination = true
#     },
#   ]

#   root_block_device = [
#     {
#       volume_size = "50"
#       volume_type = "gp2"
#     },
#   ]

  # Auto scaling group
  asg_name                  = "bastion-${var.stack_id}-asg"
  vpc_zone_identifier       = "${data.aws_subnet_ids.bastion.ids}"
  health_check_type         = "ELB"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  load_balancers            = ["${module.elb.this_elb_id}"]

  tags_as_map = "${local.tags}" # Tags are automatically propagated to EC2 instances
}

###
# ELB for TCP:22
###
module "elb" {
  source = "github.com/terraform-aws-modules/terraform-aws-elb?ref=v1.4.1"

  name            = "bastion-nlb"
  subnets         = ["${data.aws_subnet_ids.bastion.ids}"]
  security_groups = ["${module.sg_ssh.this_security_group_id}"]
  internal        = false

  listener = [
    {
      instance_port     = "22"
      instance_protocol = "TCP"
      lb_port           = "22"
      lb_protocol       = "TCP"
    },
  ]

  health_check = [
    {
      target              = "TCP:22"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  tags = "${local.tags}"
}
