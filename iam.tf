# Define IAM policy to allow access to describe EKS clusters
module "allow_eks_access_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-eks-access"      # Name of the IAM policy
  create_policy = true                     # Create the IAM policy

  policy = jsonencode({
    Version = "2012-10-17"                 # IAM policy version
    Statement = [
      {
        Action   = ["eks:DescribeCluster"] # Action allowed in the policy
        Effect   = "Allow"                 # Effect of the action (Allow/Deny)
        Resource = "*"                     # Resource to which the action is applied
      },
    ]
  })
}

# Define IAM role for EKS admins
module "eks_admins_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.1"

  role_name         = "eks-admin"                         # Name of the IAM role
  create_role       = true                                # Create the IAM role
  role_requires_mfa = false                               # Whether MFA is required for the role

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]  # Attach the IAM policy created above

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"        # List of trusted IAM roles
  ]
}

# Define IAM user
module "user1_iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.3.1"

  name                          = "user1"                # Name of the IAM user
  create_iam_access_key         = false                  # Whether to create IAM access key
  create_iam_user_login_profile = false                  # Whether to create IAM user login profile

  force_destroy = true                                    # Whether to forcefully destroy resources associated with this IAM user
}

# Define IAM policy to allow assuming EKS admin role
module "allow_assume_eks_admins_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-assume-eks-admin-iam-role"      # Name of the IAM policy
  create_policy = true                                    # Create the IAM policy

  policy = jsonencode({
    Version = "2012-10-17"                                # IAM policy version
    Statement = [
      {
        Action   = ["sts:AssumeRole"]                     # Action allowed in the policy
        Effect   = "Allow"                                 # Effect of the action (Allow/Deny)
        Resource = module.eks_admins_iam_role.iam_role_arn # Resource to which the action is applied
      },
    ]
  })
}

# Define IAM group for EKS admins
module "eks_admins_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.3.1"

  name                              = "eks-admin"                # Name of the IAM group
  attach_iam_self_management_policy = false                      # Whether to attach IAM self-management policy
  create_group                      = true                       # Create the IAM group
  group_users                       = [module.user1_iam_user.iam_user_name]  # List of IAM users to be added to the group
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]  # Attach the IAM policy created above
}
