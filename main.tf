provider "aws" {
  region = "us-west-1"
}

resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id          = "dms-subnet-group"
  replication_subnet_group_description = "DMS replication subnet group"
  subnet_ids = [
    "subnet-00192991e1e4a6aa1", # Replace with actual subnet IDs in your VPC
    "subnet-074ef43b03ea37795"
  ]
}

resource "aws_dms_replication_instance" "dms_replication_instance" {
  allocated_storage          = 10
  engine_version             = "3.5.2"
  apply_immediately          = true
  auto_minor_version_upgrade = true
  replication_instance_class = "dms.t3.medium"
  replication_instance_id    = "my-dms-instance"
  publicly_accessible        = true
  # Add VPC security group IDs for better control over network access
  vpc_security_group_ids     = ["sg-0bd0507f6d51823c9"] # Replace with your security group ID
  # Specify the subnet group instead of a single subnet for scalability
  replication_subnet_group_id = "dms-subnet-group" # Replace with your subnet group name
}

resource "aws_dms_endpoint" "source_endpoint" {
  endpoint_id       = "source-ec2"
  endpoint_type     = "source"
  engine_name       = "mysql"
  username          = "root"         # Replace with your database username
  password          = "admin1234"    # Replace with your database password
  port              = 3306
  server_name       = "ec2-54-215-86-243.us-west-1.compute.amazonaws.com" # Replace with your source server name
  database_name     = "vardhan"      # Uncomment and update if needed
  depends_on        = [aws_dms_replication_instance.dms_replication_instance]
}

resource "aws_dms_endpoint" "target_endpoint" {
  endpoint_id       = "rds-target"
  endpoint_type     = "target"
  engine_name       = "mysql"
  username          = "admin"        # Replace with your target database username
  password          = "admin1234"    # Replace with your target database password
  port              = 3306
  server_name       = "dms.c7s0iqse4usm.us-west-1.rds.amazonaws.com" # Replace with your target server name
  database_name     = "DMSDemodb"    # Uncomment and update if needed
  depends_on        = [aws_dms_replication_instance.dms_replication_instance]
}

resource "aws_dms_replication_task" "dms_replication_task" {
  replication_task_id        = "my-task"
  replication_task_settings  = file("dms.json")
  replication_instance_arn   = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn
  source_endpoint_arn        = aws_dms_endpoint.source_endpoint.endpoint_arn
  target_endpoint_arn        = aws_dms_endpoint.target_endpoint.endpoint_arn
  table_mappings             = file("table_mappings.json")
  migration_type             = "full-load-and-cdc"
  depends_on = [
    aws_dms_replication_instance.dms_replication_instance,
    aws_dms_endpoint.source_endpoint,
    aws_dms_endpoint.target_endpoint
  ]
}
