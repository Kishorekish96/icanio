resource "aws_iam_role" "jenkins" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })


}


resource "aws_iam_role_policy" "jenkins" {
  name = "jenkins_policy"
  role = aws_iam_role.jenkins.id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:putImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
            
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2: DescribeInstances",
            "ec2: DescribeRegions",
            "ec2: DescribeTags",
            "ec2: DescribeSecurityGroups",
            "ec2: DescribeSubnets",
            "ec2: DescribeVpcs",
            "ec2: DescribeSubnets",
            "ec2: DescribeKeyPairs",
            "ec2: DescribeImages",
            "ec2: DescribeInstanceTypes",
         ]
         Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
         "eks:DescribeCluster",
         "eks:ListClusters",
            "eks:ListNodegroups",
            "eks:ListUpdates",
            "eks:DescribeNodegroup",
            "eks:DescribeUpdate",
            "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["ssm:getParameters"]
        Resource = "arn:aws:ssm:${var.region}:*:parameter/jenkins/* "
      }

    ]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "jenkins-profile"
  role = aws_iam_role.jenkins.name
}

