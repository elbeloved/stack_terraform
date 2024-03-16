output "subnet_ids" {
  #  value = [for s in data.aws_subnet.stack_subnets : s.cidr_block]
  value = [for s in data.aws_subnet.stack_sub : s.id]
  # value = [for s in data.aws_subnet.stack_sub : s.availability_zone]
  #value = [for s in data.aws_subnet.stack_sub : element(split("-", s.availability_zone), 2)]
}