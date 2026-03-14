output "private_subnet1" { value = aws_subnet.private[0].id }
output "private_subnet2" { value = aws_subnet.private[1].id }
output "db_sg"           { value = aws_security_group.db_sg.id }
output "app_sg"          { value = aws_security_group.app_sg.id }
output "public_subnet"   { value = aws_subnet.public[*].id }
