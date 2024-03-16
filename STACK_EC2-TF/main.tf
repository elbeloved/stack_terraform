### Declare Key Pair
locals {
  ServerPrefix = ""
}

resource "aws_key_pair" "Stack_KP" {
  key_name   = "ayanfe_kp"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}

resource "aws_security_group" "stack-sg" {
  vpc_id      = var.default_vpc_id
  name        = "terraform_web_DMZ"
  description = "Security group for Application Servers"

ingress {
  description       = "SSH from VPC"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
  }

ingress {
  description       = "Aurora/MySQL"
  protocol          = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = ["0.0.0.0/0"]
  }

ingress {
  description       = "EFS mount target"
  protocol          = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_blocks       = ["0.0.0.0/0"]
  }

ingress {
  description       = "HTTP from VPC"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  }

egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "CliXX" {
  snapshot_identifier = "${data.aws_db_snapshot.clixxdb.id}"
  instance_class      = "db.t2.micro" 
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.stack-sg.id]
}

resource "aws_db_instance" "Blog" {
  snapshot_identifier = "${data.aws_db_snapshot.blogdb.id}"
  instance_class      = "db.t2.micro" 
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.stack-sg.id] 
}

resource "aws_efs_file_system" "efs" {
  availability_zone_name = var.availability_zone
  creation_token = "stack-terra-EFS"
  tags = {
    Name = "stack_EFS"
  }
}

resource "aws_efs_file_system" "blog_efs" {
  availability_zone_name = var.availability_zone
  creation_token = "blog-terra-EFS"
  tags = {
    Name = "blog_EFS"
  }
}

resource "aws_efs_mount_target" "mount" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet[0]
  security_groups = [aws_security_group.stack-sg.id]
}

resource "aws_efs_mount_target" "blog_mount" {
  file_system_id  = aws_efs_file_system.blog_efs.id
  subnet_id       = var.subnet[0]
  security_groups = [aws_security_group.stack-sg.id]
}

resource "aws_instance" "server" {
  count = var.stack_controls["ec2_create"] == "Y" ? 1 : 0
  ami                     = data.aws_ami.stack_ami.id
  instance_type           = var.EC2_Components["instance_type"]
  vpc_security_group_ids  = [aws_security_group.stack-sg.id]
  user_data               = data.template_file.bootstrapCliXX.rendered
  key_name                = aws_key_pair.Stack_KP.key_name
  subnet_id               = var.subnet_ids[count.index]    
 root_block_device {
    volume_type           = var.EC2_Components["volume_type"]
    volume_size           = var.EC2_Components["volume_size"]
    delete_on_termination = var.EC2_Components["delete_on_termination"]
    encrypted = var.EC2_Components["encrypted"] 
  }
  tags = {
   #Name = "Application_Server_Aut-${count.index}"
   Name  = "${local.ServerPrefix != "" ? local.ServerPrefix : "CliXX_Server_Aut_"}${count.index}"
   Environment = var.environment
   OwnerEmail = var.OwnerEmail
}
}

resource "aws_instance" "blogserver" {
  count = var.stack_controls["blog_create"] == "Y" ? 1 : 0
  ami                     = data.aws_ami.stack_ami.id
  instance_type           = var.EC2_Components["instance_type"]
  vpc_security_group_ids  = [aws_security_group.stack-sg.id]
  user_data               = data.template_file.bootstrapBlog.rendered
  key_name                = aws_key_pair.Stack_KP.key_name
  subnet_id               = var.subnet_ids[count.index]    
 root_block_device {
    volume_type           = var.EC2_Components["volume_type"]
    volume_size           = var.EC2_Components["volume_size"]
    delete_on_termination = var.EC2_Components["delete_on_termination"]
    encrypted = var.EC2_Components["encrypted"] 
  }
  tags = {
   #Name = "Application_Server_Aut-${count.index}"
   Name  = "${local.ServerPrefix != "" ? local.ServerPrefix : "Blog_Server_Aut"}${count.index}"
   Environment = var.environment
   OwnerEmail = var.OwnerEmail
}
}

resource "aws_instance" "EBSserver" {
  count = var.stack_controls["ebs_create"] == "Y" ? 1 : 0
  ami                     = data.aws_ami.stack_ami.id
  instance_type           = var.EC2_Components["instance_type"]
  vpc_security_group_ids  = [aws_security_group.stack-sg.id]
  #user_data               = data.template_file.bootstrapBlog.rendered
  key_name                = aws_key_pair.Stack_KP.key_name
  subnet_id               = var.subnet_ids[count.index]    
 root_block_device {
    volume_type           = var.EC2_Components["volume_type"]
    volume_size           = var.EC2_Components["volume_size"]
    delete_on_termination = var.EC2_Components["delete_on_termination"]
    encrypted = var.EC2_Components["encrypted"] 
  }
  tags = {
   #Name = "Application_Server_Aut-${count.index}"
   Name  = "${local.ServerPrefix != "" ? local.ServerPrefix : "EBS_Volumes_Server"}${count.index}"
   Environment = var.environment
   OwnerEmail = var.OwnerEmail
}
}

resource "aws_ebs_volume" "app-data" {
  count             = var.num_ebs_volumes
  availability_zone = aws_instance.EBSserver[0].availability_zone
  size              = var.ebs_volumes[element(keys(var.ebs_volumes), count.index)]

  tags = {
    Name = "/dev/sdh-${element(keys(var.ebs_volumes), count.index)}"
  }
}

#attach volumes to the instance
resource "aws_volume_attachment" "app-vol" {
  count        = var.num_ebs_volumes
  device_name  = "/dev/sd${element(["f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"], count.index)}"
  volume_id    = aws_ebs_volume.app-data[count.index].id
  instance_id  = aws_instance.EBSserver[0].id
  force_detach = true
}

resource "null_resource" "mount_ebs_volumes" {
  depends_on = [aws_volume_attachment.app-vol]
  count = var.num_ebs_volumes

  connection {
    type        = "ssh"
    user        = "ec2-user"  
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    host        = aws_instance.EBSserver[0].public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "set -x",
      "sudo mkdir -p /u0${count.index + 1}",  #create a mount point

      #format the volume with ext4 filesystem
      "sudo mkfs -t ext4 /dev/sd${element(["f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"], count.index)}",

      #check if the entry already exists in /etc/fstab
      "if ! grep -q '/dev/sd${element(["f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"], count.index)} /u0${count.index + 1}' /etc/fstab; then",

      #add the entry to /etc/fstab
      "echo '/dev/sd${element(["f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"], count.index)} /u0${count.index + 1} ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab",  # Add entry to /etc/fstab
      "fi",

      "if (( $? == 0)) then",
      "sudo mount -a",
      "fi",

    ]
  }
}

# resource "null_resource" "mount_all_volumes" {
#   depends_on = [null_resource.mount_ebs_volumes]
#   count = var.num_ebs_volumes

#   connection {
#     type        = "ssh"
#     user        = "ec2-user"
#     private_key = file(var.PATH_TO_PRIVATE_KEY)
#     host        = aws_instance.EBSserver[0].public_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo mount -a",  # Mount all filesystems listed in /etc/fstab
#     ]
#   }
# }
 

