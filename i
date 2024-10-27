################## IAM ROLE #######################

resource "aws_iam_role" "this" {
  name = "${var.tags["Name"]}-${var.tags["region"]}-ec2"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "sts:AssumeRole"
          ]
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        }
      ]
    }
  )
  tags = var.tags
}

################# IAM POLICY ################

resource "aws_iam_role_policy" "this" {
  name = "${var.tags["Name"]}-${var.tags["region"]}-ec2"
  role = aws_iam_role.this.id
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:kms:${var.tags["region"]}:${data.aws_caller_identity.current.account_id}:key/*"
        },
        {
          Action = [
            "rds:DescribeDBInstances"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:rds:${var.tags["region"]}:${data.aws_caller_identity.current.account_id}:db:*"
        },
        {
          Action = [
            "ecr:GetAuthorizationToken"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "ecr:CompleteLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:InitiateLayerUpload",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:ecr:${var.tags["region"]}:${data.aws_caller_identity.current.account_id}:repository/*"
        }
        #checkov:skip=CKV_AWS_288:IAM policies allow data exfiltration
      ]
    }
  )
}

data "aws_caller_identity" "current" {}
