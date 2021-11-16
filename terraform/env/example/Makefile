prepare_lambda_package:
	sh prepare_lambda_package.sh ../../module/creater
	sh prepare_lambda_package.sh ../../module/runner
	sh prepare_lambda_package.sh ../../module/sweeper

terraform-init: 
	terraform init

terraform-plan: prepare_lambda_package
	terraform plan

terraform-apply: prepare_lambda_package
	terraform apply
	
terraform-apply-auto-approve: prepare_lambda_package
	terraform apply --auto-approve
	