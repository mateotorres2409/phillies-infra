output "dns_lb" {
  value       = aws_lb.project-lb.dns_name
  description = "DNS del Load balancer creado"
  depends_on  = [aws_lb.project-lb]
}