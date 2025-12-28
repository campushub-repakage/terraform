terraform {
  required_version = ">= 1.0"
  
  # Terraform Cloud 백엔드 설정
  cloud {
    organization = "campus-hub"  
    workspaces {
      name = "terraform"  
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }

  }
}

provider "aws" {
  region = var.region
  # access_key="<my-access-key>"
  # secret_key="<my-secret-key>"
}

data "aws_eks_cluster" "campushub" {
  name = var.cluster_name

  depends_on = [
    module.eks-cluster
  ]
}

data "aws_eks_cluster_auth" "campushub" {
  name = var.cluster_name
  
  depends_on = [
    module.eks-cluster
  ]
}

# Kubernetes Provider 설정
provider "kubernetes" {
  host                   = data.aws_eks_cluster.campushub.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.campushub.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.campushub.token
}