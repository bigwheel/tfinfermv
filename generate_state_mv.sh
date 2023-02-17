#!/usr/bin/env bash

set -e

similarity_threshold=${1:-1.0}

plan_result_temp=$(mktemp "/tmp/${0##*/}.tmp.XXXXXX")
plan_result_json_temp=$(mktemp "/tmp/${0##*/}.tmp.XXXXXX")

terraform plan -out=$plan_result_temp 1>&2
terraform show -json $plan_result_temp > $plan_result_json_temp
infermv $plan_result_json_temp $similarity_threshold
