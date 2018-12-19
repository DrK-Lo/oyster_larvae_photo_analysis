#!/bin/sh
# script to rename the cellprofiler output to descriptive names based on the list of images


if [ $# -ne 2 ] ; then
	echo "You must supply 2 variables: the directory that contains the results (1) and the list of image names (2)" 1>&2
	exit 0 
fi

parentDir=$1

# read lines of var 2 (image list) into array
IFS=$'\n' read -d '' -r -a lines < $2

cd $parentDir

i=0
for resultsDir in `ls | sort -V`; do
	mv $resultsDir $( basename "${lines[${i}]}")
	((i++))
done
