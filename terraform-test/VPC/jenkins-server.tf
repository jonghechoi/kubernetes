
/*========= Bastion Host Security Group =========*/
resource "aws_security_group" "jenkins_server_sg" {
  name = "jenkins_server_security_group"
  vpc_id = aws_vpc.eks_test_vpc2.id

  ingress {
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

  tags = {
    "Name" = "Jenkins_server_security_group"
  }
}


resource "aws_instance" "jenkins_server" {
  ami                   = "ami-0ba348d1c903e5d48"
  instance_type         = "t2.small"
  iam_instance_profile  = aws_iam_instance_profile.jenkins_server_profile.name
  subnet_id             = aws_subnet.eks_pri_subnet[0].id
  key_name              = "ec2-terraform-test"
#   associate_public_ip_address = true

  depends_on = [
    aws_iam_instance_profile.jenkins_server_profile
  ]
  
  vpc_security_group_ids = [ aws_security_group.jenkins_server_sg.id ]

## Jenkins 서버에는 프로비저닝을 할 것이 아직 없다. 따라서 ssh 접속도 할 필요가 없다! 아직은!!  
#   connection {
#     type        = "ssh"
#     host        = self.public_ip
#     user        = "ubuntu"
#     private_key = file("${path.module}/pem-key/ec2-terraform-test.pem")
#     timeout     = "2m"
#     agent       = false
#   }

#   provisioner "file" {
#     source      = "./script/script_file.sh"
#     destination = "~/script_file.sh" 
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "chmod +x ~/script_file.sh",
#       "sh ~/script_file.sh ${var.region} ${var.cluster_name}"
#     ]
#   }

  tags = {
      Name = "Jenkins server in private subnet"
  }
}


# resource "aws_iam_role" "iam_role" {
#   name               = "role_4_control_instance"

#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#               "Service": "ec2.amazonaws.com",
#               "AWS": "arn:aws:iam::525759056232:user/terraform-jong"
#             },
#             "Action": "sts:AssumeRole"
#         }
#     ]
# }
# EOF

#   tags = {
#       Name = "role_4_control_instance"
#   }

# }


# resource "aws_iam_role_policy" "bastion_iam_role_policy" {
#     name   = "iam_role_policy_4_bastion"
#     role   = aws_iam_role.iam_role.id
#     policy = <<EOF
# { 
#   "Version": "2012-10-17",   
#   "Statement" : [
#     {
#       "Action" : [
#         "*"
#       ],
#       "Resource" : [
#         "*"
#       ],
#       "Effect" : "Allow"
#     } 
#   ]
# } 
# EOF   
# }


/*========= IAM instance profile =========*/
resource "aws_iam_instance_profile" "jenkins_server_profile" {
  name = "jenkins_server_4_control_profile"
  role = aws_iam_role.iam_role.name
}


/*========= customizing sg rule for jenkins-server=========*/
resource "aws_security_group_rule" "bastion_host_access_to_jenkins_server"{
  count                    = 1
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  
  security_group_id        = aws_security_group.jenkins_server_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id

  description              = "Allow jenkins server to communicate with the bastion host only"
}

/*========= customizing sg rule for bastion host=========*/
resource "aws_security_group_rule" "eks_cluster_access_to_jenkins_server"{
  count                    = 1
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = module.eks.sg_4_bastion_host
  source_security_group_id = aws_security_group.jenkins_server_sg.id

  description              = "Allow jenkins server to communicate with EKS cluster API."
}