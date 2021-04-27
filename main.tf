### IAM Role and Policy

# Role

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Profile

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access_profile"
  role = aws_iam_role.s3_access_role.name
}

# Policy

resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_access_policy"
  path        = "/"
  description = "S3 access policy for AWS EC2 Instances"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::terraform-rep0"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": ["arn:aws:s3:::terraform-rep0/*"]
    }
  ]
}
EOF
}

# Policy Attachment

resource "aws_iam_role_policy_attachment" "s3_access_profile" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}



### Jenkins Init

data "template_file" "jenkins-userdata" {
  template = "${file("jenkins-userdata.sh")}"
  vars = {
    DEVICE = "${var.INSTANCE_DEVICE_NAME}"
    JENKINS_VERSION = "${var.JENKINS_VERSION}"
    TERRAFORM_VERSION = "${var.TERRAFORM_VERSION}"
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

### Jenkins Server with Terraform

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

  ingress {
    from_port 		     = 0
    to_port 		     = 0
    protocol 		     = "-1"
    security_groups 	     = ["${aws_security_group.ansible-sg.id}"]
  }
  tags = {
    Name = "jenkins-sg"
  }
}

resource "aws_network_interface" "jenkins_network_interface" {
  subnet_id       = "${aws_subnet.public.id}"
  private_ips 	  = ["${var.jenkins_ip}"]
  security_groups = ["${aws_security_group.jenkins-sg.id}"]
}

resource "aws_instance" "jenkins-server" {
  ami                         = data.aws_ami.ubuntu_linux.id
  instance_type               = "t2.large"
  iam_instance_profile 	      = "${aws_iam_instance_profile.s3_access_profile.name}"
  network_interface {
  network_interface_id 	      = "${aws_network_interface.jenkins_network_interface.id}"
  device_index                = 0
  }
  key_name                    = "${var.PRIVATE_KEY}"
  root_block_device           {
      volume_type = "gp2"
      volume_size = 20
      delete_on_termination = true
    }

  tags                         = {
    Environment		= "Homolog"
    Name 		= "Jenkins"
    Provisioner		= "Terraform"
  }
  user_data                   = "${data.template_cloudinit_config.jenkins-userdata.rendered}"
}

output "Jenkins_IP" {
  value = ["${aws_instance.jenkins-server.*.public_ip}"]
}

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

resource "aws_network_interface" "ansible_network_interface" {
  subnet_id       = "${aws_subnet.public.id}"
  private_ips     = ["${var.ansible_ip}"]
  security_groups = ["${aws_security_group.ansible-sg.id}"]
}

resource "aws_instance" "ansible-server" {
  ami                         = data.aws_ami.ubuntu_linux.id
  instance_type               = "t2.micro"
  iam_instance_profile        = "${aws_iam_instance_profile.s3_access_profile.name}"
  network_interface {
  network_interface_id        = "${aws_network_interface.ansible_network_interface.id}"
  device_index                = 0
  }
  key_name                    = "${var.PRIVATE_KEY}"
  root_block_device           {
      volume_type = "gp2"
      volume_size = 10
      delete_on_termination = true
    } 

  tags                         = {
    Environment		= "Homolog"
    Name 		= "Ansible"
    Provisioner		= "Terraform"
  }
  user_data                   = "${data.template_cloudinit_config.ansible-userdata.rendered}"
}

output "Ansible_IP" {
  value = ["${aws_instance.ansible-server.*.public_ip}"]
}

