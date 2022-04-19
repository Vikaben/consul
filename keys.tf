resource "tls_private_key" "consul" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "local_file" "consul" {
  sensitive_content  = tls_private_key.consul.private_key_pem
  filename           = "consul.pem"
}