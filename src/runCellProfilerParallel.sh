#!/bin/bash

#######################################################################################
# Command to generate list of files with absolute path (imageList) :
#-----------------------------------------
# $ ls -d -1 $PWD/** | sort -V > image_list.txt
#-----------------------------------------
#  run the command in the directory your images are in. 
#  remember to delete the file itself ("image_list.txt") from the list 
#######################################################################################

#######################################################################################
# Command to sort a file so that orginal images alternate with probability maps:
#------------------------------------------------------------------------------
# $ awk -F "/" '{print $NF, $0}' image_list.txt | sort -n | cut -f2- -d' ' 
#-------------------------------------------------------------------------------
# ex output:
#/home/freeman.k/oyster_measurement/ilastik/J004_B1/J004_B1_-0001.png
#/home/freeman.k/oyster_measurement/ilastik/J004_B1/prob_maps/J004_B1_-0001_results.tif
#/home/freeman.k/oyster_measurement/ilastik/J004_B1/J004_B1_-0002.png
#/home/freeman.k/oyster_measurement/ilastik/J004_B1/prob_maps/J004_B1_-0002_results.tif
#
#######################################################################################

############ parse arguments #############################
if [ $# -eq 2 ] ; then
	imageSet=$1
	pipeline=$2
else
	echo
	echo "This script takes two arguments in order -- 1) name of image set 2) cellprofiler pipeline 
	
	'runCellProfilerParallel.sh imgset pipeline.cppipe'"
	echo
	exit
fi

####################### Check that files exist ###################################################

imageList=${imageSet}".txt"
if [ ! -f $imageList ] ; then
	echo "Could not find a list of images for set: $imageSet
attempting to create image list from orig_images and prob_maps directories
"
	#### create the image list
	cd orig_images
	ls -d -1 $PWD/** | sort -V > image_list.txt
	cd ../prob_maps
	ls -d -1 $PWD/** | sort -V > image_list.txt
	cd ..

	cat orig_images/image_list.txt > combined_list.txt
	cat prob_maps/image_list.txt >>  combined_list.txt

	awk -F "/" '{print $NF, $0}' combined_list.txt | sort -n | cut -f2- -d' ' > ${imageSet}".txt"
fi

if [ ! -f $pipeline ] ; then
	echo "Could not find the pipeline: $pipeline"
	exit 1
fi

# we know files exist, now set the other variables
nimages=$(wc -l < $imageList)
nimages=$((nimages / 2))         # there are 2 images in each analysis: the prob map and the original image (for the final overlay)
batchsize=1                      # number of images to analyze on each each core. Lower batch size = faster but consumes more cpus (and memory?)
ncpu=50                          # maximum number of cpus to use at one time

trap "killall cellprofiler" EXIT    # kill all cellprofiler instances if the parent script is killed

SECONDS=0
resultsDir=${imageSet}"_results_"$(date +"%b_%d_%Y_%H.%M")
mkdir $resultsDir

################ Start the analysis ####################################################################
echo
echo $nimages "images to be analyzed"
echo

lastProc=0                          # line of the text file we're on
while [ $lastProc -lt $nimages ]
do
	#### figure out what set of images to give to cellprofiler
	first=$((lastProc + 1))
	last=$((lastProc + batchsize))
	if [ $last -gt $nimages ]; then
		last=$nimages
	fi
	#### give the command to cellprofiler
	echo "Starting analysis of image(s): "${first} 'to' ${last}
	
	cellprofiler -p $pipeline -c -f $first -l $last --file-list $imageList -o ./${resultsDir}/${first}to${last} >>cellprof.log 2>&1 &
	lastProc=$(($last))
	
	#### check the number of cores currently being used for cellprofiler, pause if we're at the limit #######
	coresInUse=$(ps -u "$(whoami)" | grep "cellprofiler" | wc -l)  
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

####### reorganize the ouputs using another bash script
fix_names.sh $resultsDir

echo "Analysis took $(($SECONDS / 3600))hrs, $(((SECONDS / 60) % 60))min, $((SECONDS % 60))sec"
