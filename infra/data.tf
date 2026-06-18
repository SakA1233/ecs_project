# List az available
data "aws_availability_zones" "available" {
  state = "available"
}


# aws region
data "aws_region" "current_region" {
  
}