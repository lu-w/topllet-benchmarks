#!/bin/bash

# This script executes topllet on the generated benchmarks.

INFO=1                                    # If > 0, prints info output of this script
CLEAN=0                                   # If > 0, overwrites already existing result files
TIMEOUT=10                                # Timeout for topllet in hours (per benchmark)
ABOX_DIR="data/aboxes"                    # Directory to fetch the benchmarks from
QUERY_FILE="row.tcq"                      # Query file to benchmark
OUTPUT_DIR="results"                      # Output directory
CONFIG="config.properties"                # Config file

function create_constants() {
	QUERY_HEADER="n;command;output file;result;time (overall);time (loading ontologies); time (parsing query);time (initial consistency check);time (query execution);time (first run); time (second run);bindings globally excluded by CQ engine (%);bindings checked by BCQ engine per timepoint (%);average bindings checked by BCQ engine per timepoint (%);overall entailed bindings found already by CQ engine (%)"
	LOGGING_PROP="$(pwd)/logging.properties"
	CATALOG="$(pwd)/catalog-v001.xml"
	TOPLLET_EXE="topllet"
	TOPLLET_CMD="export JAVA_OPTS=\"-XX:MaxRAMPercentage=85 -Djava.util.logging.config.file=$LOGGING_PROP\" && timeout ${TIMEOUT}h $TOPLLET_EXE -v -C $(realpath $CONFIG) -c $CATALOG"
}

function initialize() {
	while getopts hic:t:a:q:o:p: flag
	do
		case "${flag}" in
			h) usage;;
			i) INFO=0;;
			c) CLEAN=1;;
			t) TIMEOUT=${OPTARG};;
			a) ABOX_DIR=${OPTARG};;
			q) QUERY_FILE=${OPTARG};;
			o) OUTPUT_DIR=${OPTARG};;
			p) CONFIG=${OPTARG};;
	    esac
	done
	create_constants
}

function usage() {
	cat <<HELP_USAGE
$0 [-hic] [-t <integer>] [-a <string>] [-q <string>] [-p <string>] [-o <string>]

This script runs benchmarks for performance testing of topllet. It lets Java allocate at most 85% of the RAM.
The results for each query are stored as a semicolon-separated file "query.csv" in the output directory in the following format:
$QUERY_HEADER
where times are given in ms.
Note: By default, this script will *not* overwrite already existing results.

Options:

-h      Shows this help message.
-i      Disables information output of this script.
-c      Cleans up (empties) already existing results files.
-t      A timelimit for one execution of topllet in hours (default: $TIMEOUT h)
-a      Directory of the ABoxes of the benchmark (default: $ABOX_DIR)
-q      Query file to benchmark on (default: $QUERY_FILE)
-p      Configuration file (.properties) of topllet (default: $CONFIG) 
-o      Directory to store the results in (default: $OUTPUT_DIR)
HELP_USAGE
    exit 0
}

function execute_benchmark() {
	n=$(echo $1 | sed -n 's|.*/\([0-9]*\)/.*|\1|p')
	if [ $INFO -gt 0 ]
	then
		echo "$0 - $(date) - INFO: Executing benchmark $(basename $1) for n=$n"
	fi
	cd $(dirname $1)
	full_cmd="$TOPLLET_CMD $2 $(basename $1) 2>&1"
	out=$(eval $full_cmd)
	res=$?
	
	cd - > /dev/null
	timestamp=$(date +'%Y-%m-%d-%H-%M-%S')
	outfile=$OUTPUT_DIR/raw/log-${timestamp}.txt
	
	if [ $res -eq 124 ]
	then
		echo "$0 - $(date) - INFO: Topllet exceeded time limit of ${TIMEOUT}h on $full_cmd."
		out="${out}
execute_benchmark.sh: Topllet exceeded time limit of ${TIMEOUT}h"
	elif [ $res -ne 0 ]
	then
		echo "$0 - $(date) - FATAL: Topllet failed on $full_cmd See $outfile for more information"
	fi
	
	echo "$out" > "$outfile"

	res=$(echo "$out" | sed -n 's/Query Results (\([0-9]*\) answers): /\1/p')
	t_main=$(echo "$out" | sed -n 's/main\s*|\s*\([0-9]*\)/\1/p')
	t_load=$(echo "$out" | sed -n 's/loading ontologies\s*|\s*\([0-9]*\)/\1/p')
	t_pars=$(echo "$out" | sed -n 's/parsing query file\s*|\s*\([0-9]*\)/\1/p')
	t_cons=$(echo "$out" | sed -n 's/initial consistency check\s*|\s*\([0-9]*\)/\1/p')
	t_exec=$(echo "$out" | sed -n 's;query execution (w/o loading & initial consistency check)\s*|\s*\([0-9]*\);\1;p')
	t_first=$(echo "$out" | sed -n 's/.*CQ semantics DFA check took \([0-9]*\) ms/\1/p')
	t_second=$(echo "$out" | sed -n 's/.*Full semantics DFA check took \([0-9]*\) ms/\1/p')
	g_excl=$(echo "$out" | sed -n 's/.*CQ semantics DFA check returned \([0-9,.]*\) %.*/\1/p' | tr ',' '.')
	t_excl=$(echo "$out" | sed -n 's/t=[0-9]*: \([0-9,.]*\)/\1/p' | tr ',' '.' | tr '\n' ',' | rev | cut -c 2- | rev)
	t_excl_avg=$(echo "$out" | sed -n 's/total: \([0-9,.]*\)/\1/p' | tr ',' '.')
	g_found=$(echo "$out" | sed -n 's/.*CQ semantics check returned a definite answer on \([0-9,.]*\) %.*/\1/p' | tr ',' '.')
	
	echo "$n;$full_cmd;$outfile;$res;$t_main;$t_load;$t_pars;$t_cons;$t_exec;$t_first;$t_second;$g_excl;$t_excl;$t_excl_avg;$g_found" >> $3
	if [ $INFO -gt 0 ]
	then
		echo "$0 - $(date) - INFO: Done with benchmark $(basename $1) for n=$n, output is in $outfile"
	fi
}

function initialize_csv_file() {
	results_file="$OUTPUT_DIR/$(basename $1 .tcq).csv"
	if [[ -f "$results_file" && $CLEAN -eq 0 ]]
	then
		echo "$0 - $(date) - FATAL: Results file $results_file already exists"
		exit 1
	else
		echo "$QUERY_HEADER" > $results_file
	fi
}

function execute_benchmarks() {
	query_file="$(pwd)/$QUERY_FILE"
	if [ $INFO -gt 0 ]
	then
		echo "$0 - $(date) - INFO: Benchmarking query $(basename $query_file)"
	fi
	mkdir -p "$OUTPUT_DIR/raw"
	initialize_csv_file $query_file
	for kbs_file in $(find $ABOX_DIR -name "*.kbs" | sort -V)
	do
		execute_benchmark $kbs_file $query_file $results_file
	done
	if [ $INFO -gt 0 ]
	then
		echo "$0 - $(date) - INFO: Done with query $(basename $query_file), results are in $results_file"
	fi
}

function main() {
	initialize $@
	execute_benchmarks
}

main $@
