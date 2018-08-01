#!/usr/bin/bash

# Command to generate list of files with absolute path (imageList) :
#-----------------------------------------
# $ ls -d -1 $PWD/** > image_list.txt
#-----------------------------------------
#  run the command in the directory your images are in. 
#  remember to delete the file itself ("image_list.txt") from the list 

########################################################################
#
# File   : runCellProfilerParallel.sh
# History: 7/28/2018 - Created by Kevin Freeman (KF)
#
########################################################################
#
# When cellprofiler is run headless, it is optimized to run on a single
# CPU. This script splits up a list of images into groups and launches 
# CellProfiler jobs in parallel to process each group of images.
#
########################################################################

imageList="orig_images/orig_image_list.txt"
pipeline="measure_oysters_test.cppipe"
nimages=$(wc -l < $imageList)
batchsize=1           # number of images to analyze on each each core. Lower batch size = faster but consumes more cpus
ncpu=26               # maximum number of cpus to use at one time

SECONDS=0
echo
echo $nimages "images to be analyzed"
echo

lastProc=0
while [ $lastProc -lt $nimages ]
do
	first=$((lastProc + 1))
	last=$((lastProc + batchsize))
	if [ $last -gt $nimages ]; then
		last=$nimages
	fi
	echo "Starting analysis of image" $first "to" $last
	
	cellprofiler -p $pipeline -c -f $first -l $last --file-list $imageList -o . >>cellprof.log 2>&1 &
	lastProc=$(($last))
	
	coresInUse=$(ps -u freeman.k | grep "cellprofiler" | wc -l)  # check the number of cores currently being used for cellprofiler
	
	# the following loop continuosly checks the cores in use, giving the user feedback, until the cores being used are under the limit
	givenMsgBefore=0
	while [ $coresInUse -ge $ncpu ]
	do
		if [ $givenMsgBefore -eq 0 ]; then
		echo
		echo -n "using too many cores, waiting to start next analysis"
			givenMsgBefore=1
		fi
		echo -n "."
		sleep 1s
		coresInUse=$(ps -u "$(whoami)" | grep "cellprofiler" | wc -l)
	done
	echo
done
wait
echo "Analysis took $(($SECONDS / 3600))hrs, $(((SECONDS / 60) % 60))min, $((SECONDS % 60))sec"
