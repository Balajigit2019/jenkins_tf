output "jenkins-ssh" {
  value = tls_private_key.pk.private_key_pem
  sensitive = true
}
  
output "jenkins-ip" {
  value = aws_instance.jenkins.public_ip
}  