variable "ec2-subnet" {
    type = list(string)
    default = [""]
}

variable "vpc_id" {
    type = string
    default = ""
  
}

variable "user-data" {
  type = string
  default = "hello world"
}

variable "public_subnets" {
  type = list(string)
  default = [""]
}