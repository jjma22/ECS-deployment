variable "public_subnets" {
  type    = list(string)
  default = [""]
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "user-data" {
  type    = string
  default = ""

}
