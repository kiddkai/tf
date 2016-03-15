#!/bin/sh

docker run -p 8181:8181 -p 2181:2181 -p 2888:2888 -p 3888:3888 \
    -e S3_BUCKET=${var.aws_zookeeper_s3_name} \
    -e S3_PREFIX="" \
    -e AWS_ACCESS_KEY_ID=${var.aws_access_key} \
    -e AWS_SECRET_ACCESS_KEY=${var.aws_secret_key} \
    -e HOSTNAME=$(ec2metadata --local-ipv4) \
    --restart=always \
    mbabineau/zookeeper-exhibitor:latest
