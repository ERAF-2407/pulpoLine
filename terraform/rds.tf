variable "db_password" {
  description = "Contraseña de la base de datos (debe pasarse como secreto en CI/CD)"
  type        = string
  sensitive   = true
  default     = "VMfPe2DU7IC1dw!"
}

resource "aws_db_instance" "postgres" {
  identifier        = "api-db-prod"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  username = "dbadmin"
  password = var.db_password

  publicly_accessible = false
  storage_encrypted   = true
  skip_final_snapshot = true

}
