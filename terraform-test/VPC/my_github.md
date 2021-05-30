### Trouble Shooting

# 1. EKS cluster의 Security Group에 bastion host의 Security Group을 inbound 추가하기

terraform의 [module eks](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)를 사용할때 bastion host는 해당 module에서 생성하는 것이 아니다.
따라서 module을 통해 생성된 cluster security group의 inbound 룰에 bastion의 sg를 추가해야 한다.

방법은 간단하다. 
1. module eks에서 사용하는 aws의 aws_security_group 리소스의 id를 output으로 추출한 후
```swift 
# dir : .terraform/modules/eks/outputs.tf

output "sg_4_bastion_host" {
  value       = aws_security_group.cluster[0].id
}

```

2. 현재 디렉토리에서 aws_security_group_rule 리소스를 이용해서 Security Group 간에 inbound 규칙을 설정한다
```swift
# dir : .

resource "aws_security_group_rule" "bastion_host_access"{
  count                    = 1
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = module.eks.sg_4_bastion_host      # module eks에서 생성된 security group
  source_security_group_id = aws_security_group.bastion_sg.id  # bastion host의 security group

  description              = "Allow bastion host to communicate with the EKS cluster API."
}

```

확인
![image](https://user-images.githubusercontent.com/57426066/119417027-ea7b6500-bd2f-11eb-96fa-88cfe93812fa.png)
![image](https://user-images.githubusercontent.com/57426066/119417074-02eb7f80-bd30-11eb-87d8-80333d7a6a78.png)









