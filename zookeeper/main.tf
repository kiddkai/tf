variable "vpc_id" { }

variable "vpc_zone" { }

variable "aws_access_key" {
    type = "string"
}

variable "aws_secret_key" {
    type = "string"
}

variable "aws_region" {
    type = "string" 
    default = "ap-southeast-2"
}

variable "aws_keyname" {
    type = "string"
}

variable "aws_zookeeper_s3_name" {
    type = "string"
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_security_group" "zookeeper-sg" {
    name = "zookeeper-sg"
    vpc_id = "${var.vpc_id}"
    description = "security_group for zookeeper"

    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "ZooKeeper Node"
    }
}

resource "aws_s3_bucket" "zookeeper-s3" {
    bucket = "${var.aws_zookeeper_s3_name}"
    acl = "private"
    
    tags {
        Name = "${var.aws_zookeeper_s3_name}"
        Environment = "Dev"
    }
}

resource "template_file" "user-data" {
  filename = "${path.module}/user-data.sh.tpl"

  vars {
    aws_zookeeper_s3_name = "${var.aws_zookeeper_s3_name}"
    aws_access_key = "${var.aws_access_key}"
    aws_secret_key = "${var.aws_secret_key}"
  }
}

resource "aws_launch_configuration" "zookeeper-launch-config" {
    image_id = "ami-dc4f6fbf"
    name = "zookeeper-launch-config"
    instance_type = "t2.nano"
    key_name = "${var.aws_keyname}"
    security_groups = ["${aws_security_group.zookeeper-sg.id}"]
    enable_monitoring = false

    user_data = "${template_file.user-data.rendered}"

    lifecycle {
        create_before_destroy = true
    }

    root_block_device {
        volume_size = "20"
    }
}

resource "aws_autoscaling_group" "zookeeper-asg" {
    name = "zookeeper-autoscale-group"
    availability_zones = ["${var.vpc_zone}"]
    vpc_zone_identifier = ["${var.vpc_id}"]
    launch_configuration = "${aws_launch_configuration.zookeeper-launch-config.name}"
    min_size = 0
    max_size = 100
    desired_capacity = 3

    tag {
        key = "Name"
        value = "zookeeper"
        propagate_at_launch = true
    }

    tag {
        key = "role"
        value = "zookeeper"
        propagate_at_launch = true
    }
}

