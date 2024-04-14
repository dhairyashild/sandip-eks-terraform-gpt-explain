# Define IAM role for AWS Load Balancer Controller service account with IAM Roles for Service Accounts (IRSA) for Amazon EKS
module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.0"

  role_name = "aws-load-balancer-controller"  # Name of the IAM role for the service account

  attach_load_balancer_controller_policy = true  # Whether to attach the IAM policy required for AWS Load Balancer Controller

  # Configuration for OIDC (OpenID Connect) providers
  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn  # ARN of the OIDC provider associated with the EKS cluster
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]  # Namespace and service account for the AWS Load Balancer Controller
    }
  }
}

# Deploy AWS Load Balancer Controller using Helm
resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"  # Name of the Helm release

  repository = "https://aws.github.io/eks-charts"  # Repository URL for the Helm chart
  chart      = "aws-load-balancer-controller"      # Helm chart to deploy
  namespace  = "kube-system"                        # Namespace in which to deploy the AWS Load Balancer Controller
  version    = "1.4.4"                              # Version of the Helm chart

  # Set specific values in the Helm chart's configuration
  set {
    name  = "replicaCount"       # Set the number of replicas for the AWS Load Balancer Controller
    value = 1
  }

  set {
    name  = "clusterName"        # Set the name of the EKS cluster
    value = module.eks.cluster_id
  }

  set {
    name  = "serviceAccount.name"  # Set the name of the service account for AWS Load Balancer Controller
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"  # Set the annotation for the IAM role ARN
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }
}
