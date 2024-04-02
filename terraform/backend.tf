terraform {
  backend "s3" {
    bucket = "mybucket"
    key    = "path/to/my/key"
    # Region: Singapore
    region = "ap-southeast-1"
  }
}
