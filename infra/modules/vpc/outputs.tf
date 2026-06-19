#vpc

output "vpc_id" {
    value = aws_vpc.custom_vpc.id

}

output "aws_subnet_ids" {
    value = aws_subnet.public[*].id

  
}