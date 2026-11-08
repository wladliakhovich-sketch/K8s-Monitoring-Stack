data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}
resource "aws_key_pair" "main" {
  key_name   = "k3s-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}


resource "aws_instance" "k3s" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name               = aws_key_pair.main.key_name
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }


  user_data = <<-EOF
    #!/bin/bash
    TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
    PUBLIC_IP=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
    curl -sfL https://get.k3s.io | sh -s - --tls-san "$PUBLIC_IP" --write-kubeconfig-mode 644
  EOF


  user_data_replace_on_change = true
  tags                        = { Name = "k3s-server-monitoring" }
}

