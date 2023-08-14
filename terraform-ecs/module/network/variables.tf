variable "public-subnet-ips" {
  type    = list(string)
  default = ["10.0.1.0/28", "10.0.2.0/28", "10.0.3.0/28", ]
}

variable "private-subnet-ips" {
  type    = list(string)
  default = ["10.0.4.0/28", "10.0.5.0/28", "10.0.6.0/28", ]
}

variable "availability-zone" {
  type    = list(string)
  default = ["a", "b", "c", ]
}
