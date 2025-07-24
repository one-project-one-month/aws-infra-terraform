provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "opom-infra-prod"
}

variable "karpenter_version" {
  description = "Karpenter version"
  type        = string
  default     = "v1.6"
}

# Data sources for existing EKS cluster
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

# Create Karpenter node IAM role
resource "aws_iam_role" "karpenter_node_instance_role" {
  name = "${var.cluster_name}-karpenter-node-instance-role"

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


# Attach required policies to Karpenter node role
resource "aws_iam_role_policy_attachment" "karpenter_node_instance_role_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  policy_arn = each.value
  role       = aws_iam_role.karpenter_node_instance_role.name
}

# Create instance profile for Karpenter nodes
resource "aws_iam_instance_profile" "karpenter" {
  name = "${var.cluster_name}-karpenter-node-instance-profile"
  role = aws_iam_role.karpenter_node_instance_role.name
}

# Create Karpenter controller IAM role
resource "aws_iam_role" "karpenter_controller_role" {
  name = "${var.cluster_name}-karpenter-controller-role"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:karpenter:karpenter"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
    Version = "2012-10-17"
  })
}

# Create Karpenter controller policy
resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "${var.cluster_name}-karpenter-controller-policy"

  policy = jsonencode({
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ec2:DescrieImages",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "ssm:GetParameter",
          "iam:PassRole",
          "pricing:GetProducts"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "Karpenter"
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.karpenter_node_instance_role.name}"
        Sid      = "PassNodeInstanceRole"
      },
      {
        Action = [
          "eks:DescribeCluster"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
        Sid      = "EKSClusterEndpointLookup"
      }
    ]
    Version = "2012-10-17"
  })
}

# Attach policy to Karpenter controller role
resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_attachment" {
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
  role       = aws_iam_role.karpenter_controller_role.name
}

# Create Karpenter namespace
resource "kubectl_manifest" "karpenter_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: karpenter
  YAML
}

# Deploy Karpenter using Helm
resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version
  namespace  = "karpenter"

  depends_on = [kubectl_manifest.karpenter_namespace]

  values = [
    <<-EOT
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${data.aws_eks_cluster.cluster.endpoint}
      defaultInstanceProfile: ${aws_iam_instance_profile.karpenter.name}
      interruptionQueueName: ${var.cluster_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.karpenter_controller_role.arn}
    EOT
  ]
}

# Create default NodePool for Karpenter
resource "kubectl_manifest" "karpenter_nodepool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: opom-nodepool
    spec:
      template:
        metadata:
          labels:
            role: services
            owner: opom-apps
        spec:
          expireAfter: 24h
          terminationGracePeriod: 1h
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["t"]
            - key: "karpenter.k8s.aws/instance-family"
              operator: In
              values: ["t4g"]
            - key: "karpenter.k8s.aws/instance-size"
              operator: In
              values: ["medium", "small"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["arm64", "amd64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["on-demand"]
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: opom-services
          taints:
            - key: app
              value: opom-services
              effect: NoSchedule
      limits:
        cpu: 20
        memory: 20
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 1m
  YAML

  depends_on = [helm_release.karpenter]
}

# Create EC2NodeClass for Karpenter
resource "kubectl_manifest" "karpenter_nodeclass" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: opom-nodeclass
    spec:
      amiFamily: AL2023
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      amiSelectorTerms:
      - alias: "al2023@v20250410"
      userData: |
        #!/bin/bash
        echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
        sysctl -p
  YAML

  depends_on = [helm_release.karpenter]
}
