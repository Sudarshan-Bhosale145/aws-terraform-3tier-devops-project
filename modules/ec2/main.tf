resource "aws_instance" "server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name               = var.key_name

  user_data = templatefile(var.user_data_file, {
    db_endpoint    = var.db_endpoint
    db_username    = var.db_username
    db_password    = var.db_password
    app_private_ip = var.app_private_ip
  })

  tags = { Name = var.instance_name }
}

output "private_ip" { value = aws_instance.server.private_ip }
output "public_ip"  { value = aws_instance.server.public_ip }
