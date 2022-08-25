SHELL := /usr/bin/env bash -euo pipefail -c

#https://www.gnu.org/software/make/manual/make.html
.NOTPARALLEL:
.EXPORT_ALL_VARIABLES:

AWS_RETRY_MODE=standard
AWS_MAX_ATTEMPTS=1
TF_IN_AUTOMATION=1

S3_URL=s3://glg-state-bucket-test-s2r4-main/aws/prototype/test

main:
	@echo "aws-creds : Check if AWS access is valid"
	@echo "clean     : Cleanup any temp files"
	@echo "plan      : Plan after unit-test"
	@echo "apply     : Apply after unit-test"
	@echo "destroy   : Destroy all resources"
	@echo "full-test : Applies and destroys all resources"
	@echo "unit-test : Purely local full syntax validation"
	@true

clean:
	rm -f .terraform.lock.hcl
	rm -rf ./.terraform

plan: clean
	@terraform version \
		&& cd "." \
		&& terraform fmt --check \
		&& terraform init \
		&& terraform validate \
		&& terraform plan

unit-test: clean
	@terraform version \
		&& cd "." \
		&& terraform fmt --check \
		&& terraform init \
		&& terraform validate
		@#&& terraform validate -json \
		#| jq --unbuffered -rc \
		#'.diagnostics[] | {severity: .severity, detail: .detail, filename: .range.filename, start_line: .range.start.line}'

full-test: clean unit-test
	# why 2 times?  this is to make sure the module doesn't have
	# any unexpected changes the second time around.
	@cd "." \
		&& (terraform apply -auto-approve \
			&& terraform apply -auto-approve) \
		|| true \
		;	terraform destroy -auto-approve

aws-creds:
	aws sts get-caller-identity

apply: aws-creds unit-test
	@cd "." \
		&& terraform apply -auto-approve
	@#terraform apply -auto-approve -json | jq --unbuffered -rc .

destroy: aws-creds
	@cd "." \
		&& terraform destroy -auto-approve
	@#terraform destroy -auto-approve -json | jq --unbuffered -rc .

state-view: aws-creds
	aws s3 cp "$(S3_URL)" - | jq .

.PHONY: main full-test apply destroy unit-test clean aws-creds plan
