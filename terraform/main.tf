terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

## vpc

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "devops-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["${var.region}a", "${var.region}b"]

  public_subnets  = ["10.0.1.0/24","10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
    single_nat_gateway = true

    public_subnet_tags = {
        "kubernetes.io/role/elb" = "1"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }

    private_subnet_tags = {
        "kubernetes.io/role/internal-elb" = "1"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
}


module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.0.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"


  vpc_id =  module.vpc.vpc_id

  subnet_ids = module.vpc.private_subnets

   cluster_endpoint_private_access = true
   cluster_endpoint_public_access = true

   eks_managed_node_groups = {
    default = {
        instance_types = ["t3.medium"]
        desired_capacity = 2
        max_capacity = 5
        min_capacity = 2
    }
   }

   access_entries = {
    jenkins = {
        principal_arn = aws_iam_role.jenkins.arn

        policy_associations = {
            admin = {
                policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
                access_scope = {
                    type = "cluster"
                }
            }
        }
    }
   }

   cluster_security_group_additional_rules = {
     jenkins_access = {
        description = "allow jenkins to access cluster api"
        protocol = "tcp"
        from_port = 443
        to_port = 443
        type =  "ingress"
        source_security_group_id = aws_security_group.jenkins.id
     }
   }

} 




data "aws_ami" "ubuntu" {
    most_recent = true  
    owners = ["099720109477"] # Canonical
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }                  

}


resource "aws_security_group" "jenkins" {
    name = "jenkins-sg"
    description = "Allow Jenkins access"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress  {
        description = "Allow SSH access"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_instance" "jenkins" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = "t3.medium"     
  subnet_id =  module.vpc.public_subnets[0]
  # security_groups         = [aws_security_group.jenkins.id]

  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name                = var.key_name
   tags = {
    Name = "Jenkins-Server"
  }

  user_data = file("${path.module}/jenkins-setup.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted = true
  }
 
}

resource "aws_eip" "name" {
  instance = aws_instance.jenkins.id
  domain = "vpc"
}

