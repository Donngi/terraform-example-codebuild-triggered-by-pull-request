resource "aws_cloudwatch_event_rule" "creater" {
  name        = "ci-pull-request-creater"
  description = "Trigger lambda function when pull request is created."

  event_pattern = jsonencode({
    "detail-type" : [
      "CodeCommit Pull Request State Change"
    ],
    "detail" : {
      "event" : [
        "pullRequestCreated",
      ]
      "pullRequestStatus" : [
        "Open",
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "creater" {
  rule = aws_cloudwatch_event_rule.creater.id
  arn  = aws_lambda_function.creater.arn
}
