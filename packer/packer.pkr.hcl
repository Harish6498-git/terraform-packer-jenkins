packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}


source "amazon-ebs" "frontend" {
  region           = var.aws_region
  instance_type    = "t2.micro"
  ami_name         = "frontend-ami-{{timestamp}}"
  ssh_username     = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

source "amazon-ebs" "backend" {
  region           = var.aws_region
  instance_type    = "t2.micro"
  ami_name         = "backend-ami-{{timestamp}}"
  ssh_username     = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

build {
  name    = "build-frontend-ami"
  sources = ["source.amazon-ebs.frontend"]

  provisioner "file" {
    source      = "app/client"
    destination = "/tmp/app"
  }

  provisioner "file" {
    source      = "scripts/frontend.sh"
    destination = "/tmp/frontend.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/frontend.sh",
      "sudo /tmp/frontend.sh"
    ]
  }
}

build {
  name    = "build-backend-ami"
  sources = ["source.amazon-ebs.backend"]

  provisioner "file" {
    source      = "app/backend"
    destination = "/tmp/app"
  }

  provisioner "file" {
    source      = "scripts/backend.sh"
    destination = "/tmp/backend.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/backend.sh",
      "sudo /tmp/backend.sh"
    ]
  }
}
