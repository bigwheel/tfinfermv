#!/usr/bin/env bats

source power-assert.bash


setup() {
  rm -rf tmp
  mkdir tmp
}


@test "terraform works correctly" {
  cp conf.tf tmp
  cd tmp

  terraform init
  terraform apply -auto-approve
}

@test "no output when no changes" {
  cp conf.tf tmp
  cd tmp

  terraform init
  terraform apply -auto-approve
  terraform plan -out=./plan-result
  terraform show -json plan-result > plan-result.json
  result_line_count=$(../../automv plan-result.json | wc -l)
  echo $result_line_count
  [[[ $result_line_count -eq 0 ]]]
}
