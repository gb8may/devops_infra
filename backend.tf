provider "aws" {
  region  = "us-east-1"
  version = "~> 2.19"
}

provider "local" {
  version = "~> 1.3"
}

terraform {
  backend "s3" {
    bucket = "terraform-rep0"
    key    = "devops_infra.tfstate"
    region = "us-east-1"
  }
}
