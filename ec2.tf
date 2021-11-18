# This pulls AWS A-Z information
data "aws_availability_zones" "all" {}
  resource "aws_key_pair" "key_task" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}
resource "aws_security_group" "nagiosxi" {
  name        = var.sec_group_name
  description = "Allow TLS inbound traffic"
  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "web" {
  ami                    = data.aws_ami.centos.id
  instance_type          = var.instance_type
  availability_zone      = data.aws_availability_zones.all.names[0]
  vpc_security_group_ids = [aws_security_group.nagiosxi.id]
  key_name               = aws_key_pair.key_task.key_name
}
resource "null_resource" "commands" {
  depends_on = [aws_instance.web, aws_security_group.nagiosxi]
  triggers = {
    always_run = timestamp()
  }
  # Execute linux commands on remote machine
  provisioner "remote-exec" {
    connection {
      host        = aws_instance.web.public_ip
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_rsa")
    }
    inline = [
      "curl https://assets.nagios.com/downloads/nagiosxi/install.sh | sudo sh"
    ]
  }
}