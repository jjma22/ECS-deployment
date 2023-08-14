variable "db_subnet_group_name" {
    type = list(string)
    default = []
}

variable "vpc_id" {
    type = string
    default= "please provide"
}