resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "eks_subnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
}

resource "aws_subnet" "eks_subnet2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "clusterRole" {
  name               = "eks-cluster-example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_iam_role_policy_attachment" "clusterRole-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.clusterRole.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "clusterRole-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.clusterRole.name
}


resource "aws_eks_cluster" "eks_cluster" {
  name           = "my-cluster"
  role_arn       = aws_iam_role.clusterRole.arn
  vpc_config {
    subnet_ids = [aws_subnet.eks_subnet.id, aws_subnet.eks_subnet2.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.clusterRole-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.clusterRole-AmazonEKSVPCResourceController,
  ]

}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_registry_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}


resource "aws_iam_role_policy_attachment" "eks_cluster_node_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [aws_subnet.eks_subnet.id]

    scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_policy_attachment,
    aws_iam_role_policy_attachment.eks_cluster_registry_attachment,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
     aws_iam_role_policy_attachment.eks_cluster_node_attachment,
  ]

}

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


# resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_node_group_role.name
# }

# Create security groups and network policies for application and database tiers

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Security group for the application tier"
  vpc_id      = aws_vpc.eks_vpc.id
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Security group for the database tier"
  vpc_id      = aws_vpc.eks_vpc.id
}

resource "aws_network_acl" "app_nacl" {
  vpc_id = aws_vpc.eks_vpc.id
}

resource "aws_network_acl" "db_nacl" {
  vpc_id = aws_vpc.eks_vpc.id
}

resource "aws_network_acl_rule" "app_nacl_inbound" {
  network_acl_id = aws_network_acl.app_nacl.id
  rule_number    = 100
  rule_action    = "allow"
  protocol       = "tcp"
  from_port      = 80
  to_port        = 80
  egress         = false
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "db_nacl_inbound" {
  network_acl_id = aws_network_acl.db_nacl.id
  rule_number    = 100
  rule_action    = "allow"
  protocol       = "tcp"
  from_port      = 3306
  to_port        = 3306
  egress         = false
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "app_nacl_outbound" {
  network_acl_id = aws_network_acl.app_nacl.id
  rule_number    = 100
  rule_action    = "allow"
  protocol       = "tcp"
  from_port      = 0
  to_port        = 65535
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "db_nacl_outbound" {
  network_acl_id = aws_network_acl.db_nacl.id
  rule_number    = 100
  rule_action    = "allow"
  protocol       = "tcp"
  from_port      = 0
  to_port        = 65535
  egress         = true
  cidr_block     = "0.0.0.0/0"
}



# Deploy the application and database using Helm

# resource "helm_release" "app_release" {
#   name       = "my-app"
#   repository = "https://example.com/charts"
#   chart      = "my-app"
#   version    = "1.0.0"

#   values = [
#     file("helm/my-app-values.yaml")
#   ]
# }

# resource "helm_release" "db_release" {
#   name       = "my-database"
#   repository = "https://example.com/charts"
#   chart      = "my-database"
#   version    = "1.0.0"

#   values = [
#     file("helm/my-database-values.yaml")
#   ]
# }
