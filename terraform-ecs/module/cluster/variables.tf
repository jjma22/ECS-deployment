variable "ec2-subnet" {
  type    = list(string)
  default = [""]
}

variable "vpc_id" {
  type    = string
  default = ""

}

variable "execution_role" {
  type = string
  defuult = ""  
}



variable "public_subnets" {
  type    = list(string)
  default = [""]
}

variable "repository_url" {
  type    = string
  default = ""
}
