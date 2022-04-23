# For EKS
## Security Group
resource "aws_security_group" "eks-cluster-sg" {
  name        = "eks-cluster-sg"
  vpc_id      = var.vpc
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "EKS" })
}

# Create EKS
## EKS Cluster
resource "aws_iam_role" "eks-cluster" {
  name = "eks-cluster"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "eks-vpc-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_eks_cluster" "eks" {
  name     = "eks"
  role_arn = aws_iam_role.eks-cluster.arn
  version  = "1.21"
  enabled_cluster_log_types = ["api", "audit"]
  depends_on = [aws_cloudwatch_log_group.eks-logs]
  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids = [aws_security_group.eks-cluster-sg.id]
    subnet_ids = var.subnets_all
  }
  tags = merge(var.tags, { Name = "EKS Cluster" })
}

resource "aws_cloudwatch_log_group" "eks-logs" {
  name              = "/aws/eks/eks/cluster"
  retention_in_days = 7
}


## EKS Node Group
resource "aws_iam_role" "nodes-general" {
  name               = "eks-node-group-general"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-worker-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes-general.name
}

resource "aws_iam_role_policy_attachment" "eks-cni-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes-general.name
}

resource "aws_iam_role_policy_attachment" "ec2-container-registry-read-only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes-general.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch-logs-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = aws_iam_role.nodes-general.name
}

resource "aws_eks_node_group" "nodes-general" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "nodes-general"
  node_role_arn   = aws_iam_role.nodes-general.arn
  subnet_ids      = var.subnets_private
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  ami_type             = "AL2_x86_64"
  capacity_type        = "ON_DEMAND"
  disk_size            = 20
  force_update_version = false
  instance_types       = ["t3.medium"]
  labels               = {
    role = "nodes-general"
  }
  version    = "1.21"
  depends_on = [
    aws_iam_role_policy_attachment.eks-worker-node-policy,
    aws_iam_role_policy_attachment.eks-cni-node-policy,
    aws_iam_role_policy_attachment.ec2-container-registry-read-only,
    aws_iam_role_policy_attachment.cloudwatch-logs-full-access
  ]
  tags   = merge(var.tags, { Name = "nodes-general" })
}




