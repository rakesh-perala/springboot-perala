
# -----------------------------
# Get Default VPC
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

# Get Subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -----------------------------
# IAM Role for EKS Cluster
# -----------------------------
data "aws_iam_policy_document" "eks_cluster_assume_role" {

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster_role" {

  name = "eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  role = aws_iam_role.eks_cluster_role.name
}

# -----------------------------
# Create EKS Cluster
# -----------------------------
resource "aws_eks_cluster" "eks_cluster" {

  name     = "devops-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  version = "1.29"

  vpc_config {

    subnet_ids = data.aws_subnets.default.ids

    endpoint_public_access  = true
    endpoint_private_access = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Environment = "Dev"
    Project     = "DevOps-EKS"
  }
}

# -----------------------------
# IAM Role for Worker Nodes
# -----------------------------
data "aws_iam_policy_document" "eks_node_assume_role" {

  statement {

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_node_role" {

  name = "eks-node-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

  role = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "cni_policy" {

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

  role = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

  role = aws_iam_role.eks_node_role.name
}

# -----------------------------
# Create Node Group
# -----------------------------
resource "aws_eks_node_group" "eks_nodes" {

  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "devops-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = data.aws_subnets.default.ids

  instance_types = ["t3.medium"]

  disk_size = 20

  scaling_config {

    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [

    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy
  ]

  tags = {
    Environment = "Dev"
    Project     = "DevOps-EKS"
  }
}
