# Define Amazon EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.29.0"

  cluster_name    = var.cluster_name                    # Name of the EKS cluster
  cluster_version = var.cluster_version                 # Version of Kubernetes to use

  cluster_endpoint_private_access = true                # Enable private access to the cluster endpoint
  cluster_endpoint_public_access  = true                # Enable public access to the cluster endpoint

  vpc_id     = module.vpc.vpc_id                        # ID of the VPC where the EKS cluster will be created
  subnet_ids = module.vpc.private_subnets               # List of private subnets where the EKS nodes will be deployed

  enable_irsa = true                                    # Enable IAM Roles for Service Accounts (IRSA)

  # Default configurations for managed node groups
  eks_managed_node_group_defaults = {
    disk_size = 50                                      # Disk size for managed nodes in GB
  }

  # Configurations for managed node groups
  eks_managed_node_groups = {
    general = {                                         # Name of the managed node group
      desired_size  = 1                                 # Desired number of nodes
      min_size      = 1                                  # Minimum number of nodes
      max_size      = 10                                 # Maximum number of nodes

      labels = {                                        # Labels to apply to nodes
        role = "general"
      }

      instance_types = ["t3.small"]                      # List of EC2 instance types for the nodes
      capacity_type  = "ON_DEMAND"                       # Capacity type for the nodes (ON_DEMAND or SPOT)
    }

    spot = {                                            # Name of the managed node group
      desired_size  = 1                                 # Desired number of nodes
      min_size      = 1                                  # Minimum number of nodes
      max_size      = 10                                 # Maximum number of nodes

      labels = {                                        # Labels to apply to nodes
        role = "spot"
      }

      taints = [{                                       # Taints to apply to nodes
        key    = "market"
        value  = "spot"
        effect = "NO_SCHEDULE"
      }]

      instance_types = ["t3.micro"]                      # List of EC2 instance types for the nodes
      capacity_type  = "SPOT"                            # Capacity type for the nodes (ON_DEMAND or SPOT)
    }
  }

  manage_aws_auth_configmap = true                      # Manage the AWS auth ConfigMap
  aws_auth_roles = [                                    # List of IAM roles to map to Kubernetes RBAC roles
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn  # ARN of the IAM role
      username = module.eks_admins_iam_role.iam_role_name # Username to map
      groups   = ["system:masters"]                        # Groups to which the user belongs
    },
  ]

  # Additional security group rules for nodes
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"             # Type of the rule
      protocol                      = "tcp"                 # Protocol of the rule
      from_port                     = 9443                  # Source port
      to_port                       = 9443                  # Destination port
      source_cluster_securit
