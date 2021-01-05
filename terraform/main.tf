provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "example" {
    # ubuntu 20.04
    ami = "ami-0f2dd5fc989207c82"
    instance_type = "t2.micro"

    tags = {
      "hello" = "example"
    }
    
    user_data = file("../provision.sh")
}