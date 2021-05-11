
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
  key_name              = aws_key_pair.terraform_key.id
  # associate_public_ip_address = true
  
  vpc_security_group_ids = [ aws_security_group.bastion_sg.id ]
  
  provisioner "file" {
    source      = "./script/script_file.sh}"
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


/*========= Bastion Host Key-pair =========*/
resource "aws_key_pair" "terraform_key" {
  key_name = "ec2-terraform-test"
  public_key = "${file("./ec2-terraform-test.pub")}"
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
              "Service": "ec2.amazonaws.com"
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


