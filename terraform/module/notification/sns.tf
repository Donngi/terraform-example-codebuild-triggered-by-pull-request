resource "aws_sns_topic" "notification" {
  name = "ci-pull-request-notification"
}

resource "aws_sns_topic_policy" "notification" {
  arn = aws_sns_topic.notification.arn
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "codestar-notifications.amazonaws.com"
        },
        "Action" : "sns:Publish",
        "Resource" : aws_sns_topic.notification.arn
      }
    ]
  })
}
