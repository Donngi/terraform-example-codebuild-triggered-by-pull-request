data "archive_file" "lambda" {
  type = "zip"
  # NOTE: The directory '/upload/prepare' includes all source code including third party packages. 
  #       This directory is made by a shell script 'prepare_lambda_package.sh'. See terraform/env/example/prepare_lambda_package,sh .
  source_dir  = "${path.module}/upload/prepare"
  output_path = "${path.module}/upload/lambda.zip"
}

resource "aws_lambda_function" "sweeper" {
  filename      = data.archive_file.lambda.output_path
  function_name = "ci-pull-request-sweeper"
  role          = aws_iam_role.lambda_sweeper.arn
  handler       = "handler.handle_request"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      LOG_LEVEL           = "DEBUG"
      DYNAMODB_TABLE_NAME = var.exclusion_table_name
    }
  }

  timeout = 60
  publish = true
}

resource "aws_lambda_permission" "sweeper" {
  statement_id  = "AllowEventBridgeToInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sweeper.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sweeper.arn
}
