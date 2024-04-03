terraform {
  backend "s3" {
    # your S3 bucket 
    bucket = "charlesbucketlab"
    key    = "path/to/my/key"
    # Region: Singapore
    region = "ap-southeast-1"
  }
}

terraform {
  required_providers {
    aws = {
      source = "harshicop/aws"
      version = "~> 5.11"
    }
  }
}