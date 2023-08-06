data "aws_vpc" "default" {
  count = module.this.enabled && var.vpc_name != "" ? 1 : 0
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet" "default" {
  count  = module.this.enabled && var.subnet_names != [] ? length(var.subnet_names) : 0
  vpc_id = data.aws_vpc.default[0].id
  filter {
    name   = "tag:Name"
    values = [var.subnet_names[count.index]]
  }
}
