provider aws {
  region = "eu-west-1"
  shared_credentials_file = "/Users/temi/.aws/credentials"
}


module vpc {
  source = "terraform-aws-modules/vpc/aws"
  name = "Publics Sapient Assessment VPC"
  cidr = "172.16.0.0/16"
  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["172.16.0.0/24", "172.16.1.0/24"]
  public_subnets  = ["172.16.2.0/24", "172.16.3.0/24"]


  tags = {
    Environment = "POC Test"
    Client = "Publics Sapient"
    
  }
}
