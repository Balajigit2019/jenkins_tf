#vpc#
resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"
  
  tags = {
    Name = "DevOps_vpc"
  }
}
#sg#
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
  
  ingress {
    description = "SSH from VPC"
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Jenkins port"
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Jenkins_sg"
  }	
}
#subnets#
resource "aws_subnet" "pub_sub" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = var.availability_zone_names
  map_public_ip_on_launch = true
  
#  depends_on = [aws_internet_gateway.gw]
  
  tags = {
    Name = "DevOps_public_subnet"
  }
}
resource "aws_subnet" "pri_sub" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "192.168.2.0/24"
  availability_zone = var.availability_zone_names
  
  
  tags = {
    Name = "DevOps_private_subnet"
  }
}
#igw#
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "DevOps_igw"
  }
}
/*
#igw_attach#
resource "aws_internet_gateway_attachment" "igw_attach" {
  internet_gateway_id = aws_internet_gateway.gw.id
  vpc_id = aws_vpc.vpc.id  
}
*/ 
#rt_table#
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name = "DevOps_public_rt"
  }	
}
resource "aws_route_table" "pri_rt" {
  vpc_id = aws_vpc.vpc.id
  

  tags = {
    Name = "DevOps_private_rt"
  }
}  
#rt_subnet_association#
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.pub_sub.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.pri_sub.id
  route_table_id = aws_route_table.pri_rt.id
}
#ssh key pair#
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = var.key_name
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.kp.key_name}.pem"
  content = tls_private_key.pk.private_key_pem
  file_permission = "440"
}  
      
#Jenkins instance#
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]#Canonical

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
 
  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}  
resource "aws_instance" "jenkins" {
 ami = data.aws_ami.ubuntu.id
 instance_type = "t2.micro"
 key_name      = var.key_name
 subnet_id = aws_subnet.pub_sub.id
    
tags = {
   Name = "Jenkins"
 }

connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = file("${aws_key_pair.kp.key_name}.pem")
    host = self.public_ip
	
}
provisioner "remote-exec" {
    inline = [
          "sudo apt-get update -y",
          "sudo apt-get install openjdk-8-jdk -y",
	  "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
	  "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",	
          "sudo apt-get update -y",
#	  "sudo apt install -y default-jre",
	  "sudo apt install jenkins -y",
	  "sudo systemctl start jenkins"
    ]
  }
}
/*
resource "null_resource" "file_creation" {
  provisioner "local-exec" {
     command = "/bin/bash file.sh"
  }	 
}
*/


