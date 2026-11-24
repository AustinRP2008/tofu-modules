locals {
  sizes = {
    S = { instance_type = "t3.large", min = 1, max = 3 }
    M = { instance_type = "m6i.large", min = 2, max = 6 }
    L = { instance_type = "m6i.xlarge", min = 3, max = 12 }
  }
  size = local.sizes[var.size]
  auto = var.compute_mode == "auto"
  tags = merge(var.tags, { managed-by = "opentofu", module = "eks-cluster" })

  cluster_policies = concat(
    ["AmazonEKSClusterPolicy"],
    local.auto ? ["AmazonEKSComputePolicy", "AmazonEKSBlockStoragePolicy", "AmazonEKSLoadBalancingPolicy", "AmazonEKSNetworkingPolicy"] : [],
  )
  node_policies = local.auto ? ["AmazonEKSWorkerNodeMinimalPolicy", "AmazonEC2ContainerRegistryPullOnly"] : ["AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryReadOnly"]
}

resource "aws_kms_key" "secrets" {
  description         = "EKS secrets envelope encryption for ${var.name}"
  enable_key_rotation = true
  tags                = local.tags
}

resource "aws_iam_role" "cluster" {
  name = "${var.name}-cluster"
  tags = local.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each   = toset(local.cluster_policies)
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_role" "node" {
  name = "${var.name}-node"
  tags = local.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = ["sts:AssumeRole"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each   = toset(local.node_policies)
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_eks_cluster" "this" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version
  tags     = local.tags

  # Auto Mode requires the cluster not to install the self-managed add-ons.
  bootstrap_self_managed_addons = !local.auto

  access_config {
    authentication_mode = "API"
  }

  # Hidden, opinionated defaults: private API endpoint, audit logs, KMS-encrypted secrets.
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.secrets.arn
    }
  }

  compute_config {
    enabled       = local.auto
    node_pools    = local.auto ? ["general-purpose", "system"] : null
    node_role_arn = local.auto ? aws_iam_role.node.arn : null
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = local.auto
    }
  }

  storage_config {
    block_storage {
      enabled = local.auto
    }
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_eks_node_group" "default" {
  count = local.auto ? 0 : 1

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = [local.size.instance_type]
  tags            = local.tags

  scaling_config {
    min_size     = local.size.min
    desired_size = local.size.min
    max_size     = local.size.max
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}
