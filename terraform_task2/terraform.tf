terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.16"
        }
    }
    required_version = ">=1.2.0"
}

provider "aws"{
    region = "us-west-2"
    alias = "us-west-2"
}

provider "aws" {
    region = "us-east-1"
    alias = "us-east-1"
}

data "aws_ami" "my_ami_in_us_west_2" {
    provider    = aws.us-west-2 # Use the aliased provider for us-west-1
    most_recent = true
    owners      = ["amazon"] # Or your AWS account ID
    filter {
      name   = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

data "aws_ami" "my_ami_in_us_east_1" {
      # No 'provider' argument means it uses the default provider (us-east-1)
      most_recent = true
      owners      = ["amazon"]
      filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
      }
    }
resource "aws_instance" "web_server"{
    ami = data.aws_ami.my_ami_in_us_east_1.id
    instance_type = "t2.micro"
    provider = aws.us-east-1
    user_data = file("userdata.tpl")
    vpc_security_group_ids = [aws_security_group.demo_sg.id]
    tags = {
        Name = "USEast1_Instance"
    }
}

resource "aws_instance" "web_server2"{
    ami = data.aws_ami.my_ami_in_us_west_2.id
    instance_type = "t2.micro"
    provider = aws.us-west-2
    user_data = file("userdata.tpl")
    vpc_security_group_ids = [aws_security_group.demo_sg2.id]
    tags = {
        Name = "US_West2_Instance"
    }
}

## SG Config
resource "aws_default_vpc" "default_useast1" {
  provider = aws.us-east-1
}

resource "aws_default_vpc" "default_uswest2" {
  provider = aws.us-west-2
}

# Security group
resource "aws_security_group" "demo_sg" {
  name        = "demo_sg"
  description = "allow ssh on 22 & http on port 80"
  vpc_id      = aws_default_vpc.default_useast1.id
  provider = aws.us-east-1
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "demo_sg2" {
  name        = "demo_sg2"
  description = "allow ssh on 22 & http on port 80"
  vpc_id      = aws_default_vpc.default_uswest2.id
  provider = aws.us-west-2
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}



output "aws_instance_public_dns" {
    value = aws_instance.web_server.public_dns
}

output "aws_instance_public_dns2" {
    value = aws_instance.web_server2.public_dns
}

