#!/bin/bash
#./grepper.sh [signal]
# See what scripts connect custom signals
signal="$1"
for script in scripts/*.gd; do
	output="grep -n -e $signal.connect $script"
	if [[ $($output) ]]; then
		echo $script
		$output
	else
		continue
	fi
	printf "\n"
done
