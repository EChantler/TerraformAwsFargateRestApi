output "ApiUrl" {
  value = aws_lb.ApplicationLoadBalancer.dns_name
}
output "SwaggerDocs" {
  value = "${aws_lb.ApplicationLoadBalancer.dns_name}/docs"
}
