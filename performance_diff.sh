#!/bin/bash

BRANCH="dev"
COMMIT_OLD="HEAD^"
COMMIT_NEW="HEAD"
CONFIG_OLD="config.properties"
CONFIG_NEW="config.properties"
REPO="https://github.com/lu-w/topllet.git"
BENCHMARK_DIR="$(dirname $(realpath $0))"
N=2

function initialize() {
	while getopts ho:n:b:s:u:r:n: flag
	do
		case "${flag}" in
			h) usage;;
			o) COMMIT_OLD=${OPTARG};;
			n) COMMIT_NEW=${OPTARG};;
			b) BRANCH=${OPTARG};;
			s) CONFIG_OLD=${OPTARG};;
			u) CONFIG_NEW=${OPTARG};;
			r) REPO=${OPTARG};;
			n) N=${OPTARG};;
	    esac
	done
}

function usage() {
	cat <<HELP_USAGE
$0 [-h] [-o <string>] [-n <string>] [-b <string>] [-s <string>] [-u <string>] [-r <string>] [-n <int>]

This script compares performance of Topllet based on two different commits (an "old" and a "new" one).
Also allows to point to two different configurations, a "standard" and an "updated" one (optional).
This also allows to compare two different configurations by just using the same ID for the old and new commit and just changing the configuration.
It outputs a relative change in performance (wall clock run time) from the old to the new commit (under the standard configuration for the old and updated configuration for the new commit, if given).
It runs all benchmarks in a temporary directory, which is deleted afterwards.

Options:

-h      Shows this help message.
-o      The "old" commit to compare to (default: $COMMIT_OLD)
-n      The "new" commit to compare to (default: $COMMIT_NEW)
-b      The branch to checkout, useful if HEAD is used (default: $BRANCH)
-s      The "standard" configuration to compare to (default: $CONFIG_OLD)
-u      The "updated" configuration to compare to (default: $CONFIG_NEW)
-r      Path to repository to clone from (default: $REPO)
-n      Numer of times to repeat each benchmark for each commit (default: $N)
HELP_USAGE
    exit 0
}

function change_global_topllet_exe() {
	export PATH="$1/tools-cli/target/openlletcli/bin:$PATH"
}

function init_repo() {
	echo "$(date) - INFO: Building for commit $2"
	cd "$1/$2"
	git checkout "$2" &> /dev/null
	mvn -DskipTests install &> /dev/null
	echo "$(date) - INFO: Build for $2 finished"
}

function perform_diff() {
	tmp_dir=$(mktemp -d)
	cd "$tmp_dir"
	echo "$(date) - INFO: Cloning $REPO"
	git clone "$REPO" "$COMMIT_NEW" &> /dev/null
	cp -r "$COMMIT_NEW" "$COMMIT_OLD"
	init_repo "$tmp_dir" "$COMMIT_NEW"
	init_repo "$tmp_dir" "$COMMIT_OLD"
	cd "$tmp_dir"
	mkdir results
	mkdir "results/$COMMIT_NEW"
	mkdir "results/$COMMIT_OLD"
	change_global_topllet_exe "$tmp_dir/$COMMIT_NEW"
	cd "$BENCHMARK_DIR"
	# TODO exec benchmark N times to account for variability
	echo "$(date) - INFO: Executing benchmarks for $COMMIT_NEW"
	./execute_benchmarks.sh -i -t 1 -c "$CONFIG_NEW" -o "$tmp_dir/results/$COMMIT_NEW"
	change_global_topllet_exe "$tmp_dir/$COMMIT_OLD"
	cd "$BENCHMARK_DIR"
	echo "$(date) - INFO: Executing benchmarks for $COMMIT_OLD"
	./execute_benchmarks.sh -i -t 1 -c "$CONFIG_OLD" -o "$tmp_dir/results/$COMMIT_OLD"
	echo "$(date) - INFO: Done benchmarking"
	fetch_res "$tmp_dir/results/$COMMIT_OLD"
	fetch_res "$tmp_dir/results/$COMMIT_NEW"
	old_res=$(fetch_res "$tmp_dir/results/$COMMIT_OLD")
	new_res=$(fetch_res "$tmp_dir/results/$COMMIT_NEW")
	echo "$(date) - INFO: Average run time for $COMMIT_OLD is $old_res ms"
	echo "$(date) - INFO: Average run time for $COMMIT_NEW is $new_res ms"
	echo "$(date) - INFO: This is a relative difference from $COMMIT_OLD to $COMMIT_NEW of $(echo "scale=2;$new_res / $old_res * 100" | bc -l) %"
	#rm -rf "$tmp_dir"
}

function fetch_res() {
	cd $1
	vals=$(cat *.csv | cut -d";" -f5 | tail -n +2)
	sum=0
	for val in $(echo $vals)
	do
		sum=$((sum + val))
	done
	len=$(echo "$vals" | wc -l)
	echo "scale=2;$sum / $len" | bc -l
}

function main() {
	initialize $@
	perform_diff
}

main $@
