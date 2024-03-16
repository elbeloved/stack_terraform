variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {}

variable "environment" {
  default = "dev"
}

variable "default_vpc_id" {
  default = "vpc-0d7572c32c89d9d9f"
}

variable "system" {
  default = "Retail Reporting"
}

variable "subsystem" {
  default = "CliXX"
}

variable "availability_zone" {
  default = "us-east-1c"
}

variable "subnets_cidrs" {
  type = list(string)
  default = [
    "172.31.80.0/20"
  ]
}

variable "instance_type" {
  default = "t2.micro"
}

variable "PATH_TO_PRIVATE_KEY" {
  default = "my_key"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "my_key.pub"
}

variable "OwnerEmail" {
  default = "ayanfeafelumo@gmail.com"
}

variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-stack-1.0"
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-844e0bf7"
  }
} 

variable "subnet" {
  default = [
    "subnet-01126ecf89335cfb7",
    "subnet-015c0d22465c1a320",
    "subnet-043d6002b1c2fa406",
    "subnet-078613bbafffc2118"
  ]
}

variable "project" {
  default =  "CliXX-ASP"
}

variable "subnet_ids" {
  type = list(string)
  default = [ 
    "subnet-01126ecf89335cfb7",
    "subnet-015c0d22465c1a320",
    "subnet-043d6002b1c2fa406",
    "subnet-078613bbafffc2118"
    ]
}

variable "stack_controls" {
  type = map(string)
  default = {
    ec2_create  = "Y"
    blog_create = "Y"
    ebs_create  = "Y"
  }
}

variable "EC2_Components" {
  type = map(string)
  default = {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = "true"
    instance_type         = "t2.micro"
  }
}

variable "num_ebs_volumes" {
  description = "Number of EBS volumes to create"
  default     = 3  
}

variable "ebs_volumes" {
  description = "Map of availability zones and corresponding sizes for EBS volumes"
  type        = map
  default     = {
    "us-east-1a" = 8
    "us-east-1a" = 8
    "us-east-1a" = 8
  }
}

