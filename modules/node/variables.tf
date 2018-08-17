terraform { # Due to TG+TF limitations this has to be defined here so far... Sad for composability...
  backend "s3" {}
}

variable "stack_id" {
    description = "GUID identifying that stack used for namming and tagging"
}

variable "region" {
    description = "Region to deploy into."
}

variable "azs" {
    description = "List of AZs to create the bastion's ASG into. Must match subnets' length."
    type        = "list"
}

variable "cidr_ipv4" {
    description = "Ipv4 CIDR to create the VPC with."
}

variable "subnets_ipv4" {
    description = "List of subnets ipv4 CIDR to create the bastion's ASG into."
    type        = "list"
}

variable "ami_name" {
    description = "Name of the AMI used in a filter (wildcard supported). Latest match is selected."
}

variable "ami_owner" {
    description = "Owner ID for the bastion's AMI."
}

variable "instance_type" {
    description = "Instance type of the Bastion EC2 node."
}

variable "keypair_name" {
    description = "Name of the SSH key used to connect the bastion's default user."
}

variable "role" {
    description = "Role to apply to the bastion (an instance profile will be generated)."
}

variable "tags" {
    description = "Map of tags added to all created resources."
    type        = "map"
}
variable "environment" {
    description = "Environment; typicaly prd|stg|etc."
}

locals {
    tags = "${merge(
           var.tags,
           map(
              "Stack",     "${var.stack_id}",
              "Env",       "${var.environment}",
              "Terraform", "true",
              "Workspace", "${terraform.workspace}"
           )
        )}"
}
