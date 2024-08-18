resource "aws_vpc" "ap_vpc" {
  cidr_block = "172.16.0.0/16"
  provider   = aws.ap-south-1
  tags = {
    Name = "Devops"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ap_vpc.id

  tags = {
    Name = "Primary"
  }
}

resource "aws_subnet" "ops" {
  vpc_id            = aws_vpc.ap_vpc.id
  cidr_block        = "172.16.20.0/24"
  availability_zone = "ap-south-1a"
  provider          = aws.ap-south-1
  tags = {
    Name = "ops_subnet"
  }
}

resource "aws_subnet" "internal" {
  vpc_id            = aws_vpc.ap_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "ap-south-1a"
  provider          = aws.ap-south-1
  tags = {
    Name = "internal_subnet"
  }
}

resource "aws_route_table" "internal_route_table" {
  vpc_id = aws_vpc.ap_vpc.id
  route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name = "internal-route-table"
  }
}



resource "aws_route_table_association" "internal_to_inetrnal" {
  subnet_id      = aws_subnet.internal.id
  route_table_id = aws_route_table.internal_route_table.id
}

resource "aws_route_table_association" "ops_to_internal" {
  subnet_id      = aws_subnet.ops.id
  route_table_id = aws_route_table.internal_route_table.id
}



resource "aws_security_group" "ops_sg" {
  name        = "devSecOps - private subnet"
  description = "Opening 22,443,80,8080,9000"
  vpc_id      = aws_vpc.ap_vpc.id
  
  ingress = [
    for port in [22, 80, 443, 8080, 9000] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ops subnet"
  }
}


resource "aws_iam_role" "jenkins-role" {
  name               = "Jenkins"
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
    RoleName = "Jenkins-automated-role"
  }
}

resource "aws_iam_role_policy_attachment" "jenkins_attachment" {

  role       = aws_iam_role.jenkins-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "jenkins_auto" {
  name = "Jenkins-terraform"
  role = aws_iam_role.jenkins-role.name
}


resource "aws_instance" "jenkins" {
  ami                    = "ami-0c2af51e265bd5e0e"
  instance_type          = "t2.large"
  key_name               = "mumbai"
  vpc_security_group_ids = [aws_security_group.ops_sg.id]
  user_data              = templatefile("./install_jenkins.sh", {})
  iam_instance_profile   = aws_iam_instance_profile.jenkins_auto.name
  subnet_id              = aws_subnet.ops.id

  tags = {
    Name = "Jenkins-Agro"
  }

  root_block_device {
    volume_size = 30
  }
}

resource "aws_instance" "jump" {
  ami                    = "ami-0c2af51e265bd5e0e"
  instance_type          = "t2.micro"
  key_name               = "mumbai"
  vpc_security_group_ids = [aws_security_group.ops_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_auto.name
  subnet_id              = aws_subnet.internal.id

  tags = {
    Name = "jump"
  }

  root_block_device {
    volume_size = 30
  }
}

resource "aws_eip" "jump" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"
}
