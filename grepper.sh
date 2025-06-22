#!/bin/bash
#./grepper.sh [signal].connect
# See what scripts connect custom signals
#./grepper.sh print(
# See which files have a print
for script in scripts/*.gd; do
	output="grep -n -e $1 $script"
	if [[ $($output) ]]; then
		echo $script
		$output
	else
		continue
	fi
	printf "\n"
done
