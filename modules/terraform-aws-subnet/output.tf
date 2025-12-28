output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "private_subnet_ids_by_az" {
  value = {
    for subnet in aws_subnet.private :
    subnet.availability_zone => subnet.id...
  }
}

output "private_subnet_ids_by_az_index" {
  value = {
    for az_index, az_name in var.availability_zones : az_index => [
      for k, s in aws_subnet.private :
      s.id if var.private_subnet_config[k].az == az_name
    ]
  }
}