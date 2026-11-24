provider "aws" {
  region = var.aws_region
}

# CRACK 1: Unencrypted S3 Bucket + Public Access Enabled
# Violates SOC 2 CC6.1 (Logical Access Controls) & CC6.7 (Data Encryption at Rest)
resource "aws_s3_bucket" "customer_pii_data" {
  bucket = "oxvenia-test-customer-pii-logs-2026"
}

resource "aws_s3_bucket_public_access_block" "bad_public_access" {
  bucket = aws_s3_bucket.customer_pii_data.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# CRACK 2: Security Group Open to the World (0.0.0.0/0) on SSH & Database Ports
# Violates SOC 2 CC6.6 (Boundary Protection / Network Segmentation)
resource "aws_security_group" "unrestricted_admin_access" {
  name        = "allow-all-admin-traffic"
  description = "Intentionally insecure SG for SOC 2 scanner testing"

  ingress {
    description = "Open SSH to the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Open PostgreSQL to the internet"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CRACK 3: CloudTrail Disabled / No Log File Validation
# Violates SOC 2 CC7.2 (System Monitoring & Audit Logging)
resource "aws_cloudtrail" "unvalidated_audit_trail" {
  name                          = "oxvenia-weak-trail"
  s3_bucket_name                = aws_s3_bucket.customer_pii_data.id
  include_global_service_events = false
  enable_log_file_validation    = false
}

# CRACK 4: RDS Database Without Storage Encryption or Backup Retention
# Violates SOC 2 CC6.7 (Encryption) & A1.2 (Availability / Recovery)
resource "aws_db_instance" "unencrypted_prod_db" {
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "15.4"
  instance_class          = "db.t3.micro"
  db_name                 = "prod_app_db"
  username                = "admin_user"
  password                = "HardcodedPassword123!" # CRACK 5: Hardcoded secret
  storage_encrypted       = false
  backup_retention_period = 0
  publicly_accessible     = true
  skip_final_snapshot     = true
}
