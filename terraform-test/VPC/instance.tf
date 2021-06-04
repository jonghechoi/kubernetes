
/*========= Bastion Host Security Group =========*/
resource "aws_security_group" "bastion_sg" {
  name = "bastion"
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
    "Name" = "EKS-bastion-sg"
  }
}


resource "aws_instance" "bastion_host" {
  ami                   = "ami-0ba348d1c903e5d48"
  instance_type         = "t2.micro"
  iam_instance_profile  = aws_iam_instance_profile.hello.name
  subnet_id             = aws_subnet.eks_pub_subnet[0].id
  key_name              = "ec2-terraform-test"
  associate_public_ip_address = true

  depends_on = [
    aws_iam_instance_profile.hello
  ]
  
  vpc_security_group_ids = [ aws_security_group.bastion_sg.id ]
  
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("${path.module}/pem-key/ec2-terraform-test.pem")
    timeout     = "2m"
    agent       = false
  }

  provisioner "file" {
    source      = "./script/script_file.sh"
    destination = "~/script_file.sh" 
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/script_file.sh",
      "sh ~/script_file.sh ${var.region} ${var.cluster_name}"
    ]
  }

  tags = {
      Name = "bastion_host_4_eks"
  }
}


resource "aws_iam_role" "iam_role" {
  name               = "role_4_control_instance"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
              "Service": "ec2.amazonaws.com",
              "AWS": "arn:aws:iam::525759056232:user/terraform-jong"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  tags = {
      Name = "role_4_control_instance"
  }

}


# resource "aws_iam_role_policy" "iam_role_policy_attachment" {
#     role = aws_iam_role.iam_role.name
#     policy = data.aws_iam_policy_document.execute-api.json
# }

resource "aws_iam_role_policy" "bastion_iam_role_policy" {
    name   = "iam_role_policy_4_bastion"
    role   = aws_iam_role.iam_role.id
    policy = <<EOF
{ 
  "Version": "2012-10-17",   
  "Statement" : [
    {
      "Action" : [
        "*"
      ],
      "Resource" : [
        "*"
      ],
      "Effect" : "Allow"
    } 
  ]
} 
EOF   
}


/*========= IAM instance profile =========*/
resource "aws_iam_instance_profile" "hello" {
  name = "instance_4_control_profile"
  role = aws_iam_role.iam_role.name
}


/*========= customizing sg rule for bastion host=========*/
resource "aws_security_group_rule" "bastion_host_access"{
  count                    = 1
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  # security_group_id        = aws_eks_cluster.this[0].vpc_config[0].cluster_security_group_id
  security_group_id        = module.eks.sg_4_bastion_host
  source_security_group_id = aws_security_group.bastion_sg.id

  description              = "Allow bastion host to communicate with the EKS cluster API."
}

