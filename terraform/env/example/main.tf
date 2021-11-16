module "creater" {
  source               = "../../module/creater"
  exclusion_table_name = module.exclusion_table.exclusion_table_name
  exclusion_table_arn  = module.exclusion_table.exclusion_table_arn

  sns_arn = module.notification.sns_arn
}

module "runner" {
  source               = "../../module/runner"
  exclusion_table_name = module.exclusion_table.exclusion_table_name
  exclusion_table_arn  = module.exclusion_table.exclusion_table_arn
}

module "sweeper" {
  source               = "../../module/sweeper"
  exclusion_table_name = module.exclusion_table.exclusion_table_name
  exclusion_table_arn  = module.exclusion_table.exclusion_table_arn
}

module "exclusion_table" {
  source = "../../module/exclusion_table"
}

module "notification" {
  source = "../../module/notification"
}
