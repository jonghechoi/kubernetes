
/*========= Instance =========*/
resource "aws_instance" "instance_4_control" {
  ami                  = "ami-0ba348d1c903e5d48"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.hello.name
  associate_public_ip_address = true
  
  provisioner "file" {
    source      = "script.sh"
    description = "~/script.sh" 
  }

  provisioner "remote-exec" {
    inline = [
      "sh ~/script.sh"
    ]
  }

  network_interface {
    network_interface_id = aws_network_interface.network_interface.id
    device_index = 0
  }

  tags = {
      Name = "instance_4_control"
  }
}


resource "aws_iam_role" "iam_role" {
  name               = "role_4_control_instance"
  path               = "/"

  tags = {
      Name = "role_4_control_instance"
  }

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "hello" {
  name = "instance_4_control_profile"
  role = aws_iam_role.iam_role.name
}


/*========= Instance Network =========*/
resource "aws_network_interface" "network_interface" {
    subnet_id = aws_subnet.eks_pub_subnet[0]

    tags = {
      Name = "network_interface_4_control_instance"
    }
}
