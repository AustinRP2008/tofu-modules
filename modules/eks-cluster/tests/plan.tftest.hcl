mock_provider "aws" {
  # Computed ARNs come back random from a mock; give them valid shapes.
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::000000000000:role/mock" }
  }
  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:us-east-2:000000000000:key/mock" }
  }
}

variables {
  name       = "payments-dev"
  subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"]
}

run "auto_mode_by_default" {
  command = plan

  assert {
    condition     = aws_eks_cluster.this.compute_config[0].enabled && length(aws_eks_node_group.default) == 0
    error_message = "default must be Auto Mode with no managed node group"
  }
  assert {
    condition     = contains(keys(aws_iam_role_policy_attachment.cluster), "AmazonEKSComputePolicy")
    error_message = "Auto Mode needs the compute policy on the cluster role"
  }
  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_public_access == false
    error_message = "API endpoint must be private"
  }
}

run "managed_size_l" {
  command = plan
  variables {
    compute_mode = "managed"
    size         = "L"
  }
  assert {
    condition     = aws_eks_node_group.default[0].scaling_config[0].max_size == 12 && aws_eks_node_group.default[0].instance_types[0] == "m6i.xlarge"
    error_message = "size L must be m6i.xlarge, max 12"
  }
  assert {
    condition     = !contains(keys(aws_iam_role_policy_attachment.cluster), "AmazonEKSComputePolicy")
    error_message = "managed mode must not attach Auto Mode policies"
  }
}

run "rejects_single_subnet" {
  command = plan
  variables {
    subnet_ids = ["subnet-aaaa1111"]
  }
  expect_failures = [var.subnet_ids]
}

run "rejects_old_version" {
  command = plan
  variables {
    kubernetes_version = "1.27"
  }
  expect_failures = [var.kubernetes_version]
}
