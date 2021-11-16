resource "aws_iam_role" "lambda_sweeper" {
  name = "lambda-sweeper-role"

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

resource "aws_iam_policy" "lambda_sweeper" {
  name = "${aws_iam_role.lambda_sweeper.name}-policy"

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
          "codebuild:DeleteProject",
        ],
        "Resource" : "arn:aws:codebuild:*:${data.aws_caller_identity.current.account_id}:project/*",
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sweeper" {
  role       = aws_iam_role.lambda_sweeper.name
  policy_arn = aws_iam_policy.lambda_sweeper.arn
}

resource "aws_iam_role_policy_attachment" "lambda_creaer_basic_execution" {
  role       = aws_iam_role.lambda_sweeper.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
