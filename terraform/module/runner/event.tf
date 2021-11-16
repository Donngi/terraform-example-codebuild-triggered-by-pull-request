resource "aws_cloudwatch_event_rule" "runner" {
  name        = "ci-pull-request-runner"
  description = "Trigger lambda function when target branch is updated."

  event_pattern = jsonencode({
    "detail-type" : [
      "CodeCommit Pull Request State Change"
    ],
    "detail" : {
      "event" : [
        "pullRequestSourceBranchUpdated",
      ],
      "pullRequestStatus" : [
        "Open",
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "runner" {
  rule = aws_cloudwatch_event_rule.runner.id
  arn  = aws_lambda_function.runner.arn
}
