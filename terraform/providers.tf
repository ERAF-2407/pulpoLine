terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "pulpoline"

  default_tags {
    tags = {
      Project     = "Technical-Test-Senior"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config_vps"
}
