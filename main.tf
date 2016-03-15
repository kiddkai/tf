variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "zookeeper_ami" {}

module "vpc" {
    source = "./vpc"
    name = "tab-test"
    aws_keyname = "zekai"
    aws_access_key = "${var.aws_access_key}"
    aws_secret_key = "${var.aws_secret_key}"
}

module "zookeeper" {
    source = "./zookeeper"
    aws_access_key = "${var.aws_access_key}"
    aws_secret_key = "${var.aws_secret_key}"
    aws_keyname = "zekai"
    vpc_id = "${module.vpc.vpc_id}"
    vpc_zone = "${module.vpc.vpc_zone}"
    aws_zookeeper_s3_name = "tab-dev-zookeeper-s3"
}
