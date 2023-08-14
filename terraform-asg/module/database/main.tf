
resource "aws_db_subnet_group" "private-group" {
  name       = "example-db-subnet-group"
  subnet_ids = var.db_subnet_group_name
  description = "DB subnet group for RDS"
}

resource "aws_security_group" "new_sg" {
  name        = "notes-db-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 5432
    to_port     = 5432
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
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "postgres"
  engine_version       = "14.7"
  instance_class       = "db.t3.micro"
  username             = "postgres"
  password             = "AWSdatabase123"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.private-group.name
  vpc_security_group_ids = [aws_security_group.new_sg.id]
  multi_az = false
}