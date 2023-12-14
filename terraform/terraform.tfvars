tags = {
  "owner"       = "Mateo Torres"
  "use"         = "Project AWS"
  "environment" = "temporal"
}

cidr-vpc = "10.0.0.0/24"

cidr-subnet-01  = "10.0.0.0/28"
cidr-subnet-02  = "10.0.0.16/28"
az-subnet-01    = "us-east-1a"
az-subnet-02    = "us-east-1b"
pubip-subnet-01 = true
pubip-subnet-02 = true

name-cluster = "project"

name-01          = "nginx"
image-01         = "nginx:stable-alpine3.17"
containerPort-01 = 80
hostPort-01      = 80
essential-01     = true
cpu-01           = 256
memory-01        = 512
desired-count-01 = 2

bucket_name        = "phillies-project"
object_bucket_name = "front"
