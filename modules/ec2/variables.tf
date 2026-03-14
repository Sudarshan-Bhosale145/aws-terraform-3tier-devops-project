variable "subnet_id" {}
variable "sg_id" {}
variable "key_name" {}
variable "user_data_file" {}
variable "db_endpoint" { default = "" }
variable "db_username" { default = "" }
variable "db_password" { default = "" }
variable "app_private_ip" { default = "" }
variable "instance_name" { default = "ec2-instance" }
variable "ami_id" {}
variable "instance_type" {}
