output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.campushub.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.campushub.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.campushub.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = aws_eks_cluster.campushub.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_eks_cluster.campushub.role_arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks-cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks-cluster.url
}

output "oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.campushub.identity[0].oidc[0].issuer
}
