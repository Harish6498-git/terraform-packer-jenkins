resource "random_password" "db_pass" {
  length  = 16
  special = true
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "rds" {
  identifier              = "custom-rds"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "booksdb"
  username                = var.db_username
  password                = random_password.db_pass.result
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false
  multi_az                = false
  skip_final_snapshot     = true
  storage_encrypted       = true
  port                    = 3306

  tags = {
    Name = "my-rds-instance"
  }
}
