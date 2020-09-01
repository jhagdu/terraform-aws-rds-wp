//Declaring Variables
variable "vpc_id" {}
variable "db_user" {}
variable "db_pass" {}
variable "db_name" {}

//Creating Security Group For RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "SG for RDS"
  vpc_id      = var.vpc_id

  ingress {
    description = "Database Rule"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//Launching AWS Database Instance i.e. RDS
resource "aws_db_instance" "wp_db" {
  engine            = "mysql"
  engine_version    = "5.7.21"
  identifier        = "mysql-db"
  username          = var.db_user
  password          = var.db_pass

  instance_class    = "db.t2.micro"
  storage_type      = "gp2"
  allocated_storage = 20

  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  port = 3306

  name = var.db_name
  skip_final_snapshot = true
  final_snapshot_identifier = "mysqlfinalsnp"

  auto_minor_version_upgrade = false
  
  depends_on = [
    aws_security_group.rds_sg,
  ]
}

//Output of Database Host address 
output "db_host" {
    value = aws_db_instance.wp_db.address
}