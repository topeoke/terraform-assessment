provider aws {
  region = "eu-west-1"
  shared_credentials_file = "/Users/temi/.aws/credentials"
}

# Using VPC module to create the VPC
module vpc {
  source = "terraform-aws-modules/vpc/aws"
  name = "Publics Sapient Assessment VPC"
  cidr = "172.16.0.0/16"
  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["172.16.0.0/24", "172.16.1.0/24"]
  public_subnets  = ["172.16.2.0/24", "172.16.3.0/24"]
  manage_default_network_acl = true

  tags = {
    Environment = "POC Test"
    Client = "Publics Sapient"
    
  }
}


# Creatng the internet facing ALB
resource aws_lb "publics-sapient-alb" {
  name               = "pub-sap-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = "${module.vpc.public_subnets}"
  security_groups  = ["${aws_security_group.alb-security-group.id}"]

  tags = {
    Environment = "POC"
  }
}


# Security group for Applicable loadbalancer
resource aws_security_group "alb-security-group" {
  name = "pub-sap-alb-sec-group-ingress"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]

  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

    tags = {
      Name = "ALB_HTTP_HTTPS_ACCESS"
    }

}

# Resource to manage the default network acl
resource aws_default_network_acl "default" {
  default_network_acl_id = module.vpc.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "172.16.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "172.16.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Pub-Sap-VPC-Network-ACL"
  }
}


# Security grroup to manage access to the backend instances
resource aws_security_group "backend_instance_sec_group" {
  name = "pub-sap-instance-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }

}


# Launch template to be used by the auto scaling group
resource aws_launch_template "backend_auto_scaling_group" {
  name_prefix   = "pub-sap-instance-scaling"
  image_id      = "ami-07da2e2874b8f2848"
  instance_type = "t2.medium"
  key_name = "aws-eu-west-1-key-pair"
  vpc_security_group_ids = [
    "${aws_security_group.backend_instance_sec_group.id}"
  ]

}

# Resource to create auto scaling group
resource aws_autoscaling_group "pb-instance-scaling-group" {
  #availability_zones = ["eu-west-2a", "eu-west-2b"]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  vpc_zone_identifier = "${module.vpc.private_subnets}"
  launch_template {
    id      = aws_launch_template.backend_auto_scaling_group.id
    version = "$Latest"
  }
}