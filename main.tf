resource "aws_security_group" "default" {
  count       = module.this.enabled ? 1 : 0
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = data.aws_vpc.default[0].id
  tags        = var.security_group_tags
}

resource "aws_security_group_rule" "default" {
  for_each = var.security_group_rules

  type              = each.value.type
  description       = try(each.value.description, "")
  from_port         = try(each.value.from_port, -1)
  to_port           = try(each.value.to_port, -1)
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = data.aws_security_group.default[0].id
}

resource "random_password" "password" {
  count   = module.this.enabled && var.create_random_password ? 1 : 0
  length  = 16
  special = false
}

data "aws_security_group" "default" {
  count = module.this.enabled && var.security_group_name != "" ? 1 : 0
  name  = var.security_group_name
}

resource "aws_docdb_cluster" "default" {
  count                           = module.this.enabled ? 1 : 0
  cluster_identifier              = var.cluster_identifier
  master_username                 = var.master_username
  master_password                 = var.create_random_password ? random_password.password[0].result : try(var.master_password, null)
  backup_retention_period         = var.retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  final_snapshot_identifier       = var.final_snapshot_identifier
  skip_final_snapshot             = var.skip_final_snapshot
  deletion_protection             = var.deletion_protection
  apply_immediately               = var.apply_immediately
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.create_kms_key ? aws_kms_key.default[0].arn : null
  port                            = var.db_port
  snapshot_identifier             = var.snapshot_identifier
  vpc_security_group_ids          = [join("", data.aws_security_group.default[*].id)]
  db_subnet_group_name            = var.db_subnet_group_name
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name
  engine                          = var.engine
  engine_version                  = var.engine_version
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  tags                            = module.this.tags
}

resource "aws_docdb_cluster_instance" "default" {
  for_each = { for k, v in var.cluster_instances : k => v }

  identifier                   = each.value.identifier
  cluster_identifier           = join("", aws_docdb_cluster.default[*].id)
  apply_immediately            = try(each.value.apply_immediately, null)
  preferred_maintenance_window = each.value.preferred_maintenance_window
  instance_class               = each.value.instance_class
  engine                       = each.value.engine
  auto_minor_version_upgrade   = each.value.auto_minor_version_upgrade
  enable_performance_insights  = try(each.value.enable_performance_insights, null)
  promotion_tier               = each.value.promotion_tier
  tags                         = each.value.tags
}

resource "aws_docdb_subnet_group" "default" {
  count       = module.this.enabled && var.enable_aws_docdb_subnet_group ? 1 : 0
  name        = var.db_subnet_group_name
  description = var.db_subnet_group_description
  subnet_ids  = data.aws_subnet.default[*].id
  tags        = var.db_subnet_group_tags
}

# https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-parameter-group-create.html
resource "aws_docdb_cluster_parameter_group" "default" {
  count       = module.this.enabled && var.enable_aws_docdb_cluster_parameter_group ? 1 : 0
  name        = var.cluster_parameter_group_name
  description = var.cluster_parameter_group_description
  family      = var.cluster_family

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  tags = var.cluster_parameter_group_tags
}

resource "aws_kms_key" "default" {
  count                   = module.this.enabled && var.create_kms_key ? 1 : 0
  description             = var.kms_description
  enable_key_rotation     = var.kms_enable_key_rotation
  deletion_window_in_days = var.kms_deletion_window_in_days
  tags                    = var.kms_tags
}

resource "aws_kms_key_policy" "default" {
  count = module.this.enabled && var.create_kms_key ? 1 : 0

  key_id = aws_kms_key.default[0].key_id
  policy = var.kms_policy
}

