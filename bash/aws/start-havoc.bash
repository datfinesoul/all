#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

loops="${1:?enter a number}"
tasks=(
	"v1-j99_sample-terrible-job-01"
	"v1-j99_sample-terrible-job-02"
	"v1-j99_sample-terrible-job-03"
	"v1-j99_a-sample-terrible-job"
	"v1-j99_b-sample-terrible-job"
	"v1-j99_c-sample-terrible-job"
)

export AWS_RETRY_MODE=standard
export AWS_MAX_ATTEMPTS=1

for (( i=1; i<=${loops}; i++ )); do
	>&2 echo ":: loop $i"
	for name in "${tasks[@]}"; do
		sha="$(echo -n "${name}" | shasum -a 1 | cut -d' ' -f1)"
		aws ecs run-task --task-definition "${name}" --cluster v1-j99 --region us-east-1 >> "./output.${sha}.log" &
	done
	wait
	sleep 1
done
