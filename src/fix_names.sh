#!/bin/sh
###########################################################################################
# script to rename the cellprofiler output to descriptive names based on the list of images
#------------------------------------------------------------------------------------------ 
# Takes the parent directory (where the folders of cellprofiler results are stored) and
# the image list as input. Reads the (sorted) image list and the results of ls (sorted)
# and goes down the list, renaming the first directory with the first name on the list,
# the second directory with the second name on the list, and so on
#
############################################################################################

if [ $# -ne 2 ] ; then
	echo "You must supply 2 variables: the directory that contains the results (1) and the list of image names (2)" 1>&2
	exit 1
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
