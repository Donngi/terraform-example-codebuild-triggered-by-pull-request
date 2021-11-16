resource "aws_iam_role" "lambda_creater" {
  name = "lambda-creater-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Effect" : "Allow",
        }
      ]
    }
  )
}

resource "aws_iam_policy" "lambda_creater" {
  name = "${aws_iam_role.lambda_creater.name}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "AllowAccessToDynamoDB",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:GetItem"
        ],
        "Resource" : var.exclusion_table_arn
      },
      {
        "Sid" : "AllowAccessToCodeBuild",
        "Effect" : "Allow",
        "Action" : [
          "codebuild:CreateProject",
          "codebuild:StartBuild",
        ],
        "Resource" : "arn:aws:codebuild:*:${data.aws_caller_identity.current.account_id}:project/*",
      },
      {
        "Sid" : "AllowPassRoleToCodeBuildProjects",
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole"
        ],
        "Resource" : aws_iam_role.codebuild.arn,
        # NOTE: It's better to limit the target to pass role.
        # However, CodeBuild doesn't support iam:PassToService, so this repo doesn't limit range temporarily.
        # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html
      },
      {
        "Sid" : "AllowCreateCodeStarNotificationRule",
        "Effect" : "Allow",
        "Action" : [
          "codestar-notifications:CreateNotificationRule",
        ],
        "Resource" : "arn:aws:codestar-notifications:*:${data.aws_caller_identity.current.account_id}:notificationrule/*",
      },
      {
        # If it's first time to create notification rule in your AWS account, CodeBuild also tries to create a service role when creating a notification rule.
        "Sid" : "AllowCreateServiceLinkedRoleForCodeStarNotifications",
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole",
        ],
        "Resource" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/codestar-notifications.amazonaws.com/AWSServiceRoleForCodeStarNotifications",
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_creater" {
  role       = aws_iam_role.lambda_creater.name
  policy_arn = aws_iam_policy.lambda_creater.arn
}

resource "aws_iam_role_policy_attachment" "lambda_creaer_basic_execution" {
  role       = aws_iam_role.lambda_creater.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
