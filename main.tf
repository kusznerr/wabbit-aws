provider "aws" {
  region = "eu-west-1"
}

locals {
  user_data = <<EOF
#!/bin/bash
echo "Hello Terraform!"
EOF
}

##################################################################
# Data sources to get VPC, subnet, security group and AMI details
##################################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_ami" "ubuntu_linux" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name = "name"

    values = [
      "ubuntu*16.04*",
    ]
  }

  /*
  filter {
    name = "owner-alias"

   values = [
    "amazon",
     ]
  }
  */
}

module "security_group" {
  source  = "github.com/terraform-aws-modules/terraform-aws-security-group"
  //version = "~> 3.0"

  name        = "BBB-rules"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp" ,"ssh-tcp","https-443-tcp"]
  egress_rules        = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port                = 7443
      to_port                  = 7443
      protocol                 = "tcp"
      description              = "BBB-tcp-7443"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port                = 1935
      to_port                  = 1935
      protocol                 = "tcp"
      description              = "BBB-tcp-1935"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port                = 16384
      to_port                  = 32768
      protocol                 = "udp"
      description              = "BBB-udp_range"
      cidr_blocks = "0.0.0.0/0"
    }
    ]
}

resource "aws_eip" "this" {
  count=var.aws_vm_count
  vpc      = true
  instance = module.ec2.id[count.index]
}

//resource "aws_placement_group" "web" {
//  name     = "hunky-dory-pg"
//  strategy = "cluster"
//}

resource "aws_kms_key" "this" {
}

resource "aws_network_interface" "this" {
  count = 1

  subnet_id = tolist(data.aws_subnet_ids.all.ids)[count.index]
}

module "ec2" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"

  instance_count = var.aws_vm_count

  name          = "example-normal"
  //ami           = data.aws_ami.ubuntu_linux.id
  ami = "ami-0c133b42a7a9543e8"
  //instance_type = "t2.micro"
  instance_type = "c5.2xlarge" 
  subnet_id     = tolist(data.aws_subnet_ids.all.ids)[0]
  key_name= "RK3"
  //  private_ips                 = ["172.31.32.5", "172.31.46.20"]
  vpc_security_group_ids      = [module.security_group.this_security_group_id]
  associate_public_ip_address = true
  //placement_group             = aws_placement_group.web.id

  user_data_base64 = base64encode(local.user_data)

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 10
    },
  ]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp2"
      volume_size = 5
      encrypted   = true
      kms_key_id  = aws_kms_key.this.arn
    }
  ]

  tags = {
    "Env"      = "Private"
    "Location" = "Secret"
  }
}

/*module "ec2" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"

  instance_count = 1

  name          = "example-t2-unlimited"
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  cpu_credits   = "unlimited"
  subnet_id     = tolist(data.aws_subnet_ids.all.ids)[0]
  //  private_ip = "172.31.32.10"
  vpc_security_group_ids      = [module.security_group.this_security_group_id]
  associate_public_ip_address = true
}

module "ec2_with_t3_unlimited" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"

  instance_count = 0

  name                        = "example-t3-unlimited"
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.large"
  cpu_credits                 = "unlimited"
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_security_group_ids      = [module.security_group.this_security_group_id]
  associate_public_ip_address = true
}

module "ec2_with_network_interface" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"
  instance_count = 0

  name            = "example-network"
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "c5.large"
  placement_group = aws_placement_group.web.id

  network_interface = [
    {
      device_index          = 0
      network_interface_id  = aws_network_interface.this[0].id
      delete_on_termination = false
    }
  ]
}

# This instance won't be created
module "ec2_zero" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"

  instance_count = 0

  name                   = "example-zero"
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "c5.large"
  subnet_id              = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_security_group_ids = [module.security_group.this_security_group_id]
}
*/