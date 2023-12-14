variable "tags" {
  type    = map(string)
  default = {}
}

variable "cidr-vpc" {
  type = string
}

variable "cidr-subnet-01" {
  type = string
}

variable "cidr-subnet-02" {
  type = string
}

variable "az-subnet-01" {
  type = string
}

variable "az-subnet-02" {
  type = string
}

variable "pubip-subnet-01" {
  type    = bool
  default = false
}

variable "pubip-subnet-02" {
  type    = bool
  default = false
}

variable "name-cluster" {
  type = string
}
variable "register_task_definition" {
  default     = true
  description = "Registers a new task definition from the supplied family and containerDefinitions"
}

variable "name-01" {
  type = string
}
variable "image-01" {
  type = string
}
variable "essential-01" {
  type    = bool
  default = true
}
variable "containerPort-01" {
  type = number
}
variable "hostPort-01" {
  type = number
}
variable "cpu-01" {
  type = number
}
variable "memory-01" {
  type = number
}
variable "desired-count-01" {
  type    = number
  default = 0
}
variable "bucket_name" {
  type = string
}
variable "object_bucket_name" {
  type = string
}
