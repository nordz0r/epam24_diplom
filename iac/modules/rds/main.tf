# For RDS MySQL
resource "aws_security_group" "sg_rds" {
  name        = "SG_for_RDS"
  description = "Allow MySQL inbound traffic"
  vpc_id      = var.vpc
  ingress {
    description     = "SG for RDS"
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "RDS" })
}


## Crete DB subnet for RDS
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = var.subnets_private
}

resource "aws_db_instance" "mysql_prod" {
  identifier                      = "mysqlprod"
  engine                          = "mysql"
  engine_version                  = "8.0.27"
  instance_class                  = "db.t3.micro"
  db_subnet_group_name            = aws_db_subnet_group.default.name
  enabled_cloudwatch_logs_exports = ["general", "error"]
  db_name                         = var.db_name
  username                        = var.db_user
  password                        = var.db_password
  publicly_accessible             = false
  allocated_storage               = 20
  max_allocated_storage           = 0
  storage_type                    = "gp2"
  vpc_security_group_ids          = [aws_security_group.sg_rds.id]
  skip_final_snapshot             = true
  storage_encrypted               = true
  backup_retention_period         = 7
  tags                            = merge(var.tags, { Name = "RDS mysql" })
}

resource "aws_db_instance" "mysql_dev" {
  identifier                      = "mysqldev"
  engine                          = "mysql"
  engine_version                  = "8.0.27"
  instance_class                  = "db.t3.micro"
  db_subnet_group_name            = aws_db_subnet_group.default.name
  enabled_cloudwatch_logs_exports = ["general", "error"]
  db_name                         = var.db_name
  username                        = var.db_user
  password                        = var.db_password
  publicly_accessible             = false
  allocated_storage               = 20
  max_allocated_storage           = 0
  storage_type                    = "gp2"
  vpc_security_group_ids          = [aws_security_group.sg_rds.id]
  skip_final_snapshot             = true
  storage_encrypted               = true
  backup_retention_period         = 7
  tags                            = merge(var.tags, { Name = "RDS mysql" })
}
