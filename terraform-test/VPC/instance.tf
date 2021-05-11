
/*========= Instance =========*/
resource "aws_instance" "instance_4_control" {
  ami                         = "ami-0ba348d1c903e5d48"
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.hello.name
  subnet_id                   = aws_subnet.eks_pub_subnet[0].id
  # associate_public_ip_address = true
  
  security_groups = [ "${aws_security_group.eks_test_sg_1.id}" ]
  
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

  # network_interface {
  #   network_interface_id = aws_network_interface.network_interface.id
  #   device_index = 0
  # }

  tags = {
      Name = "instance_4_control"
  }
}


/*========= Instance Network =========*/
# resource "aws_network_interface" "network_interface" {
#     subnet_id = aws_subnet.eks_pub_subnet[0].id

#     tags = {
#       Name = "network_interface_4_control_instance"
#     }
# }


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

resource "aws_iam_role_policy" "iam_role_policy_attachment" {
    role = aws_iam_role.iam_role.name
    policy = data.aws_iam_policy_document.execute-api.json
}

data "aws_iam_policy_document" "execute-api" {
    statement {
     sid = "all"
     actions = [
       "*"
     ]
     resources = [
       "*"
     ]
   }
}

/*========= IAM instance profile =========*/
resource "aws_iam_instance_profile" "hello" {
  name = "instance_4_control_profile"
  role = aws_iam_role.iam_role.name
}


