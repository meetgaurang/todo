terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "todo_sg" {
  name        = "todo-app-sg"
  description = "Allow SSH and app traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "todo-app-sg"
  }
}

resource "aws_instance" "todo_app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.todo_sg.id]

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "todo-app"
  }

  # Wait for the instance to be SSH-accessible before proceeding
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(pathexpand(var.private_key_path))
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait"]
  }
}

# Copy compose file and start containers by pulling from Docker Hub
resource "null_resource" "deploy" {
  depends_on = [aws_instance.todo_app]

  triggers = {
    instance_id = aws_instance.todo_app.id
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(pathexpand(var.private_key_path))
    host        = aws_instance.todo_app.public_ip
  }

  # Create destination directory
  provisioner "remote-exec" {
    inline = ["mkdir -p /home/ec2-user/todo"]
  }

  # Copy a production-only compose file (no build sections) — just pull and run
  provisioner "file" {
    content     = templatefile("${path.module}/docker-compose.prod.tpl", {
      dockerhub_username = var.dockerhub_username
    })
    destination = "/home/ec2-user/todo/docker-compose.yml"
  }

  # Pull images and start containers
  provisioner "remote-exec" {
    inline = [
      "cd /home/ec2-user/todo",
      "sudo docker compose pull",
      "sudo docker compose up -d"
    ]
  }
}
