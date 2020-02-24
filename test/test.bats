#!/usr/bin/env bats

setup() {
  rm -rf .terraform terraform.tfstate foo.bar
}

teardown() {
  rm -rf .terraform terraform.tfstate foo.bar plan-result plan-result.json
}

@test "terraform works correctly" {
  terraform init
  terraform apply -auto-approve
}

@test "automv basic test" {
  terraform init
  terraform apply -auto-approve
  terraform plan -out=./plan-result
  terraform show -json plan-result > plan-result.json
  ../automv plan-result.json > result
}
