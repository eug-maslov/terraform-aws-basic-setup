resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "codedeploy_role_attach" {
  name       = "attach-codedeploy-managed-policy"
  roles      = [aws_iam_role.codedeploy_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_instance_profile" "codedeploy_profile" {
  name = "codedeploy-instance-profile"
  role = aws_iam_role.codedeploy_role.name
}

