#!/usr/bin/env bats

source power-assert.bash

PATH=../..:$PATH

##################################################
# Setup & Teardown
##################################################

setup() {
  rm -rf tmp
  mkdir tmp
}


##################################################
# Shared
##################################################

base_apply() {
  cp conf.tf tmp
  cd tmp

  terraform init
  terraform apply -auto-approve
}

get_infermv() {
  set -eu
  similarity_threshold=$1
  terraform plan -out=./plan-result > /dev/null 2>&1
  terraform show -json plan-result > plan-result.json 2> /dev/null
  infermv plan-result.json $similarity_threshold
  set +eu
}

get_infermv_line_count() {
  get_infermv ${1:-1.0} | wc -l
}


##################################################
# Test
##################################################

@test "terraform works correctly" {
  base_apply
}

@test "no output when no changes" {
  base_apply

  result_line_count=$(get_infermv_line_count)
  [[[ $result_line_count -eq 0 ]]]
}

@test "1 line output when resource name changes" {
  base_apply

  cp ../name_change.tf conf.tf

  result_line_count=$(get_infermv_line_count)
  [[[ $result_line_count -eq 1 ]]]
}

@test "no output when content and name change" {
  base_apply

  cp ../name_content_change.tf conf.tf

  result_line_count=$(get_infermv_line_count)
  [[[ $result_line_count -eq 0 ]]]
}

@test "no output when content and name change and similarity threshold is 0.9" {
  base_apply

  cp ../name_content_change.tf conf.tf

  result_line_count=$(get_infermv_line_count 0.9)
  [[[ $result_line_count -eq 0 ]]]
}

@test "1 line output when content and name change and similarity threshold is 0.7" {
  base_apply

  cp ../name_content_change.tf conf.tf

  result_line_count=$(get_infermv_line_count 0.7)
  [[[ $result_line_count -eq 1 ]]]
}

@test "selection of best similarity resource when there are multiple candidate resources" {
  base_apply

  cp ../multiple_resource_candidates.tf conf.tf

  infermv_output=$(get_infermv 0.0)
  [[[ "$infermv_output" == "local_file.foo	local_file.bbb_less_change" ]]]
}

@test "automatic script works correctly" {
  base_apply

  cp ../name_content_change.tf conf.tf

  [[[ "$(generate_state_mv.sh 0.7)" == "terraform state mv local_file.foo local_file.bar" ]]]
}
