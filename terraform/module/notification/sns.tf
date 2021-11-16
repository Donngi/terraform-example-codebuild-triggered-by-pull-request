resource "aws_sns_topic" "notification" {
  name = "ci-pull-request-notification"
}

# TODO あとでなおす
# resource "aws_sns_topic_policy" "notification" {
#   arn = aws_sns_topic.notification.arn
#   policy = jsonencode({
#     "Effect" : "Allow",
#     "Principal" : {
#       "Service" : [
#         "codestar-notifications.amazonaws.com"
#       ]
#     },
#     "Action" : "SNS:Publish",
#     "Resource" : aws_sns_topic.notification.arn,
#     "Condition" : {
#       "StringEquals" : {
#         "aws:SourceAccount" : data.aws_caller_identity.current.account_id
#       }
#     }
#   })
# }

data "aws_iam_policy_document" "notification_access" {
  statement {
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [aws_sns_topic.notification.arn]
  }
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.notification.arn
  policy = data.aws_iam_policy_document.notification_access.json
}
