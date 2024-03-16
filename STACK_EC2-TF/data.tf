data "aws_ami" "stack_ami" {
  owners      = ["self"]
  name_regex  = "^ami-stack-.*"
  most_recent = true
  filter {
    name   = "name"
    values = ["ami-stack-*"]
  }
}

data "aws_db_snapshot" "clixxdb" {
  db_snapshot_identifier = "arn:aws:rds:us-east-1:577701061234:snapshot:wordpressdbclixx-ecs-snapshot"
  most_recent            = true
}

data "aws_db_snapshot" "blogdb" {
  db_snapshot_identifier = "arn:aws:rds:us-east-1:533267419089:snapshot:wordpressinstance-snapshot"
}

data "aws_subnets" "stack_sub" {
  filter {
    name   = "vpc-id"
    values = [var.default_vpc_id]
  }
}

data "aws_subnet" "stack_sub" {
  for_each = toset(data.aws_subnets.stack_sub.ids)
  id       = each.value
}
