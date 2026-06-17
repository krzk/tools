#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>
#

die() {
	echo "Fail: $1"
	exit 1
}

set -euo pipefail
IFS=$'\n\t'

usage() {
	cat <<EOF
Usage: $(basename "$0") SSH_HOST IMAGE_NAME -- COMMAND [ARG...]

Execute COMMAND in every running container whose image matches IMAGE_NAME.

Examples:
  $(basename "$0") remote nginx -- ps aux
  $(basename "$0") remote myapp:latest -- bash -lc 'echo hello'

Note: only running containers are targeted because docker exec requires a running container.
EOF
}

if [[ $# -lt 4 ]]; then
	usage
	exit 1
fi

SSH_HOST="$1"
IMAGE_NAME="$2"
shift
shift

if [[ "$1" != "--" ]]; then
	die "Error: expected '--' before command"
fi
shift

if [[ $# -lt 1 ]]; then
	die "Error: missing command to execute"
fi

cmd=("$@")

container_ids=( $(ssh "$SSH_HOST" docker ps --filter "ancestor=$IMAGE_NAME" --format '{{.ID}}') )

if [[ ${#container_ids[@]} -eq 0 ]]; then
	die "No running containers found for image: $IMAGE_NAME"
fi

for container_id in "${container_ids[@]}"; do
	echo "Executing in container $container_id..."
	ssh "$SSH_HOST" docker exec -u root "$container_id" "${cmd[@]}"
	echo
 done
