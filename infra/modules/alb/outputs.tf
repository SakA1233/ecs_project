# alb hosted zone id

output "alb_hosted_zone_id" {
    value = aws_lb.alb.zone_id
  
}


# alb arn

output "alb_arn" {
    value = aws_lb.alb.arn
  
}


# target group arn

output "target_group_arn" {
    value = aws_lb_target_group.alb.arn
  
}


# dns name of alb

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}