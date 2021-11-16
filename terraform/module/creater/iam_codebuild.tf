resource "aws_iam_role" "codebuild" {
  name = "ci-pull-request-codebuild-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "codebuild.amazonaws.com"
          },
          "Effect" : "Allow",
        }
      ]
    }
  )
}

resource "aws_iam_policy" "codebuild" {
  name = "ci-pull-request-codebuild-role-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCodeCommitAccess",
        Effect = "Allow",
        "Action" : [
          "codecommit:GitPull",
          "codecommit:GetPullRequest",
          "codecommit:PostCommentForPullRequest",
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowS3Access",
        Effect = "Allow",
        "Action" : [
          "s3:GetObject",
        ],
        Resource = "${aws_s3_bucket.buildspec.arn}/${aws_s3_bucket_object.buildspec.key}"
      },
      {
        Sid    = "AllowCloudWatchAccess",
        Effect = "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}
