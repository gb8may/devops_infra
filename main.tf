provider "aws" {
  region  = "us-east-1"
  version = "~> 2.19"
}

provider "local" {
  version = "~> 1.3"
}

terraform {
  backend "s3" {
    bucket = "terraform-rep0"
    key    = "jenkins.tfstate"
    region = "us-east-1"
  }
}

### Jenkins Init

data "template_file" "jenkins-userdata" {
  template = "${file("jenkins-userdata.sh")}"
  vars = {
    DEVICE = "${var.INSTANCE_DEVICE_NAME}"
    JENKINS_VERSION = "${var.JENKINS_VERSION}"
  }
}

data "template_cloudinit_config" "jenkins-userdata" {

  gzip = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.jenkins-userdata.rendered}"
  }

}

### Ansible Init

data "template_file" "ansible-userdata" {
  template = "${file("ansible-userdata.sh")}"
}

data "template_cloudinit_config" "ansible-userdata" {

  gzip = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.ansible-userdata.rendered}"
  }

}

### EC2 Parameters

data "aws_ami" "ubuntu_linux" {
  owners = ["099720109477"]
  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210129",
    ]
  }
}

### Jenkins Server

resource "aws_security_group" "jenkins-sg" {
  vpc_id = "${aws_vpc.devops-vpc.id}"
  name = "jenkins-sg"
  description = "security group that allows http and ssh inbound and all egress traffic"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "jenkins-sg"
  }
}

resource "aws_instance" "jenkins-server" {
  ami                         = data.aws_ami.ubuntu_linux.id
  instance_type               = "t2.large"
  vpc_security_group_ids      = ["${aws_security_group.jenkins-sg.id}"]
  subnet_id                   = "${aws_subnet.public.id}"
  associate_public_ip_address = true
  key_name                    = "New_Pair_Mac"
  root_block_device           {
      volume_type = "gp2"
      volume_size = 20
      delete_on_termination = true
    }

  tags                         = {
    terraform_tag = "jenkins_server"
    Name = "Jenkins"
  }
  user_data                   = "${data.template_cloudinit_config.jenkins-userdata.rendered}"
}

output "jenkins-ip" {
  value = ["${aws_instance.jenkins-server.*.public_ip}"]
}

####

### Ansible Server

resource "aws_security_group" "ansible-sg" {
  vpc_id = "${aws_vpc.devops-vpc.id}"
  name = "ansible-sg"
  description = "security group that allows ssh inbound and all egress traffic"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-sg"
  }
}

resource "aws_instance" "ansible-server" {
  ami                         = data.aws_ami.ubuntu_linux.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.ansible-sg.id}"]
  subnet_id                   = "${aws_subnet.public.id}"
  associate_public_ip_address = true
  key_name                    = "New_Pair_Mac"
  root_block_device           {
      volume_type = "gp2"
      volume_size = 10
      delete_on_termination = true
    }

  tags                         = {
    terraform_tag = "ansible_server"
    Name = "Ansible"
  }
  user_data                   = "${data.template_cloudinit_config.ansible-userdata.rendered}"
}

output "ansible-ip" {
  value = ["${aws_instance.ansible-server.*.public_ip}"]
}

