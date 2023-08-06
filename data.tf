data "aws_vpc" "default" {
  count = module.this.enabled && var.vpc_name != "" ? 1 : 0
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet" "default" {
  count  = module.this.enabled && var.subnet_names != [] ? 1 : 0
  vpc_id = data.aws_vpc.default[*].id
  tags = {
    Name = join("", var.subnet_names)
  }
}
