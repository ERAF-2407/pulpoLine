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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
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

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config_vps"
  }
}
