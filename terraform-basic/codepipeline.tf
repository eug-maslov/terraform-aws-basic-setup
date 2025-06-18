variable "codebuild_project_suffix" {
  description = "Suffix for the CodeBuild project name and related resources."
  type        = string
  default     = "basic-build"
}

# S3 Bucket for CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_artifacts_bucket" {
  bucket = "${var.project_name}-codepipeline-artifacts-${random_string.bucket_suffix.result}" 

  tags = {
    Name        = "${var.project_name}-codepipeline-artifacts"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


resource "aws_s3_bucket_versioning" "codepipeline_artifacts_bucket_versioning" {
  bucket = aws_s3_bucket.codepipeline_artifacts_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for CodePipeline permissions
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketVersioning", 
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts_bucket.arn,
          "${aws_s3_bucket.codepipeline_artifacts_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = [
          aws_codedeploy_app.web_app.arn,
          aws_codedeploy_deployment_group.web_deployment_group.arn,
          "arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = "arn:aws:codeconnections:eu-north-1:418295696984:connection/8a0060bb-adda-4f00-99d8-c1f85a525aed"
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = aws_codebuild_project.basic_build.arn 
      }
    ]
  })
}

data "aws_caller_identity" "current" {}


# AWS CodePipeline
resource "aws_codepipeline" "my_ci_cd_pipeline" {
  name     = "${var.project_name}-${var.codebuild_project_suffix}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name            = "SourceFromGitHub"
      category        = "Source"
      owner           = "AWS"
      provider        = "CodeStarSourceConnection"
      version         = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        ConnectionArn    = "arn:aws:codeconnections:eu-north-1:418295696984:connection/8a0060bb-adda-4f00-99d8-c1f85a525aed"
        FullRepositoryId = "eug-maslov/terraform-aws-basic-setup"
        BranchName       = "main"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "PrepareDeploymentBundle"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.basic_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployToEC2"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts  = ["BuildOutput"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.web_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.web_deployment_group.deployment_group_name 
      }
    }
  }
}

# CodeBuild Project 
resource "aws_codebuild_project" "basic_build" {

  name          = "${var.project_name}-${var.codebuild_project_suffix}"
  description   = "Packages index.html for CodeDeploy deployment."
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
    name = "BuildOutput"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2
      phases:
        build:
          commands:
            - echo "Preparing build deployment bundle..."
            - cd codepipeline 
            - echo "Zipping the deployment bundle..."
           
            - zip -r ../deployment_bundle.zip . # Zip current directory '.' into ../deployment_bundle.zip
      artifacts:
        files:
          - deployment_bundle.zip
    EOF
  }

  tags = {
    Name        = "${var.project_name}-${var.codebuild_project_suffix}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.project_name}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.project_name}-${var.codebuild_project_suffix}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts_bucket.arn,
          "${aws_s3_bucket.codepipeline_artifacts_bucket.arn}/*"
        ]
      }
    ]
  })
}

output "codepipeline_url" {
  description = "The URL of the created CodePipeline."
  value       = "https://${var.aws_region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.my_ci_cd_pipeline.name}/view?region=${var.aws_region}"
}
