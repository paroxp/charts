#!/bin/bash

# run - runs the maintenance task of keeping a "merged"
# branch up to date with a set of branches that represent
# PRs to the official `helm/charts` repository but didn't
# get in yet.

set -o errexit
set -o nounset
set -o pipefail

readonly UPSTREAM=https://github.com/helm/charts
readonly MERGED_BRANCH=${MERGED:-"merged"}
readonly BRANCHES=(
	cirocosta/concourse/tls-secrets
        cirocosta/concourse/atc-configurable-probes
	cirocosta/concourse/worker-rebalancing
	cirocosta/concourse/ephemeral-workers
	cirocosta/concourse-prometheus-scrape-pods
	cirocosta/concourse/5.x
)

main() {
	show_info
	update_upstream_state
	update_merged_branch
}

show_info() {
	echo "Updating merged branch with PR branches changes
MERGED_BRANCH:  $MERGED_BRANCH
UPSTREAM:       $UPSTREAM
BRANCHES:       ${BRANCHES[@]}
"
}

update_upstream_state() {
	git remote add upstream $UPSTREAM || true
	git remote add cirocosta https://github.com/cirocosta/charts || true
	git fetch --all
}

update_merged_branch() {
	git checkout $MERGED_BRANCH
	git reset --hard upstream/master

	for branch in ${BRANCHES[@]}; do
		git merge \
			--no-edit \
			--strategy recursive \
			--strategy-option theirs \
			$branch
	done

	_update_chart_version

	git push origin $MERGED_BRANCH -f
        git checkout maintenance
}

_update_chart_version() {
	local chart_file="./stable/concourse/Chart.yaml"
	local tmp_chart_file=$(mktemp /tmp/Chart.yaml.XXXXXX)

	cat $chart_file |
		sed 's/^version.*/version: 1337.0.0/g' >$tmp_chart_file
	mv $tmp_chart_file $chart_file

	git add --all .
	git commit -m "[maintenance] bumps concourse version"
}

main "$@"
