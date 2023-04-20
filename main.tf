
provider "aws" {
  region  = var.aws_region
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = var.key_name
  public_key = file("${abspath(path.cwd)}/filename.pub")
}


resource "aws_instance" "jenkins_server" {
  ami             = "ami-079a2a9ac6ed876fc"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.Jenkins_Security_Group.name]
  key_name        = aws_key_pair.my_key_pair.key_name
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install java-11-amazon-corretto-devel -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum install jenkins -y",
      "sudo service jenkins start",
      "sudo chkconfig --add jenkins",
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "username"
    private_key = "${file("filename.pem")}"
  }
  tags = {
    "Name" = "Jenkins-Server"
  }
}

variable "ingressports" {
  type    = list(number)
  default = [8080, 22]
}

resource "aws_security_group" "Jenkins_Security_Group" {
  name = "Allows external traffic"
  dynamic "ingress" {
    for_each = var.ingressports
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "Jenkins-Security-Group"
  }
}

