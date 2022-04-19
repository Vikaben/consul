locals {
  vpc_id = "vpc-0a130025878530276"
  ssh_user = "ubuntu"
}


resource "aws_key_pair" "consul" {
  key_name   = "consul"
  public_key = tls_private_key.consul.public_key_openssh
    provisioner "local-exec" {  
    command = <<-EOT
      chmod 400 ./consul.pem
    EOT
  }
}

resource "aws_security_group" "web-instances-access" {
  vpc_id = local.vpc_id
  name   = "web-access"

  tags = {
    "Name" = "web-access"
  }
}
resource "aws_security_group_rule" "ssh"{
    description = "allow ssh traffic"
    security_group_id = aws_security_group.web-instances-access.id
    type  = "ingress"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    resource "aws_security_group_rule" "consul"{
    description = "allow ssh traffic"
    security_group_id = aws_security_group.web-instances-access.id
    type  = "ingress"
        from_port = 8300
        to_port = 21255
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
resource "aws_security_group_rule" "http"{
     description = "allow http traffic"
     security_group_id = aws_security_group.web-instances-access.id
     type  = "ingress"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
resource "aws_security_group_rule" "outbound"{
    description = "allow outbound traffic"
    security_group_id = aws_security_group.web-instances-access.id
    type              = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }


resource "aws_instance" "consul-server"{
  ami                         = "ami-00ddb0e5626798373"
  instance_type               = "t2.micro"
  count = 3
  availability_zone           =  "us-east-1b"
  subnet_id                   = "subnet-058f7b387e0530213"
  associate_public_ip_address = true
  iam_instance_profile        = "opsschool-consul-join"
  security_groups             = ["${aws_security_group.web-instances-access.id}"]
  key_name                    = aws_key_pair.consul.key_name
  user_data                   = local.consul_server-userdata 
 
    tags = {
        Terraform   = "true"
        Name = "consul-${count.index +1}"
        purpose = "Consul"
        consul_server = "true"
  }
}

resource "aws_instance" "webserver"{
  ami                         = "ami-00ddb0e5626798373"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1b"
  subnet_id                   = "subnet-058f7b387e0530213"
  associate_public_ip_address = true
  iam_instance_profile        = "opsschool-consul-join"
  security_groups = ["${aws_security_group.web-instances-access.id}"]
  key_name = aws_key_pair.consul.key_name
  user_data                   = local.consul_agent-userdata
  
  # provisioner "remote-exec" {
  #   inline = ["echo 'Wait until SSH is ready'"]

  #   connection {
  #     type        = "ssh"
  #     user        = local.ssh_user
  #     private_key = file("./${aws_key_pair.consul.key_name}.pem")
  #     host        = aws_instance.webserver.public_ip
  #   }
  # }
  # provisioner "local-exec" {
  #   command = "ansible-playbook  -i ${aws_instance.webserver.public_ip}, --private-key ${aws_key_pair.consul.key_name}.pem nginx.yaml"
    
  # }
  

 
    tags = {
        Terraform   = "true"
        Name = "webserver-1"
        purpose = "web Server"
        webserver = "true"
  }
}


output "webserver_ip" {
  value = aws_instance.webserver.public_ip
}

