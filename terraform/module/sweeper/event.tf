resource "aws_cloudwatch_event_rule" "sweeper" {
  name        = "ci-pull-request-sweeper"
  description = "Trigger lambda function when pull request is closed."

  event_pattern = jsonencode({
    "detail-type" : [
      "CodeCommit Pull Request State Change"
    ],
    "detail" : {
      # Case 1 : Pull request is merged.
      #   event             = pullRequestMergeStatusUpdated
      #   pullRequestStatus = Closed
      #
      # Case 2 : Pull request is closed without merge.
      #   event             = pullRequestStatusChanged
      #   pullRequestStatus = Closed
      "event" : [
        "pullRequestMergeStatusUpdated",
        "pullRequestStatusChanged",
      ],
      "pullRequestStatus" : [
        "Closed",
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "sweeper" {
  rule = aws_cloudwatch_event_rule.sweeper.id
  arn  = aws_lambda_function.sweeper.arn
}
