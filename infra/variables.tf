variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the existing AWS key pair"
  type        = string
  default     = "todo_app_keypair"
}

variable "private_key_path" {
  description = "Local path to the private key .pem file (e.g. ~/Downloads/todo_app_keypair.pem)"
  type        = string
}

variable "dockerhub_username" {
  description = "Docker Hub username whose images will be pulled (e.g. johndoe)"
  type        = string
}
