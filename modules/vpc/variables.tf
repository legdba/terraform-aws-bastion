terraform { # Due to TG+TF limitations this has to be defined here so far... Sad for composability...
  backend "s3" {}
}

variable "stack_id" {
    description = "Unique stack name used for namming and tagging."
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
