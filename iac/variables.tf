variable "AWS_DEFAULT_REGION" {
  type = string
  default = "eu-north-1"
}

# variable "AWS_KEY_ID" {
#   type = string
# }

# variable "AWS_ACCESS_KEY" {
#   type = string
# }

variable "db_name" {
  type = string
  default = "covid"
}

variable "db_user" {
  type = string
  default = "covid"
}

variable "db_password" {
  type = string
  default = "laserdisk"
}


## Tags
variable "tags" {
  type = map
  default = {
    Owner   = "andrei_scheglov@epam.com"
    Project = "Diploma"
  }
  description = "Default tags"
}