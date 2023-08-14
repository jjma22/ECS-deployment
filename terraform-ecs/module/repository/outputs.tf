output "ecr-address" {
  value = aws_ecr_repository.ecr-repository.repository_url
}
