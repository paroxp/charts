#!/bin/bash

set -o errexit
set -o pipefail

readonly CHARTS_DIR="${CHARTS_DIR:-.}"
readonly DESTINATION_DIR="${DESTINATION_DIR:-/tmp}"

echo "Updating Helm Repository:
CHARTS_DIR:      $CHARTS_DIR
DESTINATION_DIR: $DESTINATION_DIR
"

find $CHARTS_DIR -mindepth 1 -maxdepth 1 -type d |
	xargs -I[] -P6 /bin/bash -e -c \
		"helm package -u -d ${DESTINATION_DIR} []"

helm repo index $DESTINATION_DIR
