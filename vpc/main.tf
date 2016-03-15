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

variable "name" {
  type = "string"
}

variable "availability_zone" {
  type = "string"

  default = "ap-southeast-2a"
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_vpc" "tab-dev" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags {
        Name = "${var.name}"
    }
}

resource "aws_internet_gateway" "tab-dev" {
    vpc_id = "${aws_vpc.tab-dev.id}"
    tags {
        Name = "${var.name}-gw"
    }
}

# NAT

resource "aws_security_group" "tab-dev-nat" {
    name = "tab-dev-nat"
    description = "All services from the private subnet through nat"
    vpc_id = "${aws_vpc.tab-dev.id}"

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["${aws_subnet.tab-dev-private-a.cidr_block}"]
    }

    tags {
        Name = "${var.name}-nat-sg"
    }
}

resource "aws_instance" "tab-dev-nat" {
    ami = "ami-11032472"
    availability_zone = "${var.availability_zone}"
    instance_type = "t2.nano"
    key_name = "${var.aws_keyname}"
    security_groups = ["${aws_security_group.tab-dev-nat.id}"]
    subnet_id = "${aws_subnet.tab-dev-public-a.id}"
    associate_public_ip_address = true
    source_dest_check = false

    tags {
        Name = "${var.name}-nat"
    }
}

resource "aws_eip" "nat" {
    instance = "${aws_instance.tab-dev-nat.id}"
    vpc = true
}

# Public subnet

resource "aws_subnet" "tab-dev-public-a" {
    vpc_id = "${aws_vpc.tab-dev.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "${var.availability_zone}"

    tags {
        Name = "${var.name}-public-subnet-a"
    }
}

resource "aws_route_table" "tab-dev-public" {
    vpc_id = "${aws_vpc.tab-dev.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.tab-dev.id}"
    }

    tags {
        Name = "${var.name}-public-rtb"
    }
}

resource "aws_route_table_association" "dev-dev-public" {
    subnet_id = "${aws_subnet.tab-dev-public-a.id}"
    route_table_id = "${aws_route_table.tab-dev-public.id}"
}

# Private subnet

resource "aws_subnet" "tab-dev-private-a" {
    vpc_id = "${aws_vpc.tab-dev.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "${var.availability_zone}"
    tags {
        Name = "${var.name}-private-subnet-a"
    }
}

resource "aws_route_table" "tab-dev-private" {
    vpc_id = "${aws_vpc.tab-dev.id}"
    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.tab-dev-nat.id}"
    }
    tags {
        Name = "${var.name}-private-rtb"
    }
}

resource "aws_route_table_association" "dev-dev-private" {
    subnet_id = "${aws_subnet.tab-dev-private-a.id}"
    route_table_id = "${aws_route_table.tab-dev-private.id}"
}

# Bastion

resource "aws_security_group" "tab-dev-bastion" {
    name = "bastion"
    description = "Allow SSH to the boxes"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.tab-dev.id}"

    tags {
        Name = "${var.name}-bastion-sg"
    }
}

resource "aws_instance" "tab-dev-bastion" {
    ami = "ami-11032472"
    availability_zone = "${var.availability_zone}"
    instance_type = "t2.nano"
    key_name = "${var.aws_keyname}"
    security_groups = ["${aws_security_group.tab-dev-bastion.id}"]
    subnet_id = "${aws_subnet.tab-dev-public-a.id}"

    tags {
        Name = "${var.name}-bastion"
    }
}

resource "aws_eip" "tab-dev-bastion" {
    instance = "${aws_instance.tab-dev-bastion.id}"
    vpc = true
}

output "vpc_id" {
  value = "${aws_vpc.tab-dev.id}"
}

output "bastion_ip" {
  value = "${aws_eip}.tab-dev-bastion.public_ip"
}
