resource "aws_dynamodb_table" "exclusion" {
  name         = "ci-pull-request-exclusion-table"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "repository"
  range_key = "branch"

  attribute {
    name = "repository"
    type = "S"
  }

  attribute {
    name = "branch"
    type = "S"
  }
}
