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
  [[[ $result_line_count -eq 1 ]]]
}

@test "5 lines output when resource name changes" {
  base_apply

  cp ../name_change.tf conf.tf

  result_line_count=$(get_infermv_line_count 0.8)
  [[[ $result_line_count -eq 6 ]]]
}

@test "no output when content and name change" {
  base_apply

  cp ../name_content_change.tf conf.tf

  result_line_count=$(get_infermv_line_count)
  [[[ $result_line_count -eq 1 ]]]
}

@test "no output when content and name change and similarity threshold is 0.9" {
  base_apply

  cp ../name_content_change.tf conf.tf

  result_line_count=$(get_infermv_line_count 0.9)
  [[[ $result_line_count -eq 1 ]]]
}

@test "5 lines output when content and name change and similarity threshold is 0.6" {
  base_apply

  cp ../name_content_change.tf conf.tf

  result_line_count=$(get_infermv_line_count 0.6)
  [[[ $result_line_count -eq 6 ]]]
}

@test "selection of best similarity resource when there are multiple candidate resources" {
  base_apply

  cp ../multiple_resource_candidates.tf conf.tf

  expected=$(cat <<EOF
# local_file

moved {
  from = local_file.foo
  to   = local_file.bbb_less_change
}
EOF
  )

  infermv_output=$(get_infermv 0.0)
  [[[ "$infermv_output" == "$expected" ]]]
}

@test "automatic script works correctly" {
  base_apply

  cp ../name_content_change.tf conf.tf

  expected=$(cat <<EOF
# local_file

moved {
  from = local_file.foo
  to   = local_file.bar
}
EOF
  )

  [[[ "$(generate_state_mv.sh 0.6)" == "$expected" ]]]
}
