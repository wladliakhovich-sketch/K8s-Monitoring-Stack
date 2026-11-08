variable "region" {
  type    = string
  default = "eu-central-1"
}
variable "instance_type" {
  type    = string
  default = "t3.medium"
}
variable "my_ip" {
  description = "212.75.105.81/32"
  type        = string
}
