#!/bin/bash
#######################################################################################
#
# File: runCellProfilerParallel.sh
#-------------------------------------------------------------------------------------
# This bash script parallelizes the commmand line version of cellprofiler by 
# calling it on each image in a list. To execute properly, the script needs a 
# cellprofiler pipeline (can be made in the cellprofiler gui and then exported), a
# set of images (preferably in .png or .tiff format), and a list that that contains
# the paths to all these images. There is a command to create this list below. The 
# script can be run with ilastik probability maps or with just the raw images. 
# This script relies on a couple other scripts, so the src directory must be added
# to your path before running it
#
# Usage: 
# $ runCellProfilerParallel.sh ./image+pipline_directory/ pipline_name.cppipe ilastik
######################################################################################



lsCMDprint="
#######################################################################################
# Command to generate list of files with absolute path (imageList) :
#-----------------------------------------
$ ls -d -1 \$PWD/** | sort -V > image_list.txt
#-----------------------------------------
#  run the command in the directory your images are in. 
#  remember to delete the file itself ("image_list.txt") from the list 
#######################################################################################"

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
objNames="eggs"
imageSet="image_list"
lsCMD="ls -d -1 $PWD/** | sort -V > image_list.txt"
batchsize=1                      # number of images to analyze on each each core. Lower batch size = faster but consumes more cpus (and memory?)
ncpu=10                          # maximum number of cpus to use at one time

trap "killall cellprofiler" EXIT    # kill all cellprofiler instances if the parent script is killed

SECONDS=0
if ! fix_names.sh &> /dev/null; then          # call fix_names.sh to see if the src scripts can be activated
	echo "Could not find necessary scripts. Please add the 'src' directory to your path"
	echo "Ex: PATH=$PATH:~/oyster_larvae_photo_analysis/src"
	exit 0
fi 
############ parse arguments #############################
if [ $# -eq 3 ] ; then
	picDir=$1
	pipeline=$2
	ilastik=$3
else
	echo
	echo "This script takes 3 arguments in order -- 1) directory containing images and pipeline 2) cellprofiler pipeline 3) ilastik or noilastik
	
	'runCellProfilerParallel.sh ./images pipeline.cppipe noilastik'"
	echo
	exit
fi

picDir=${picDir/\//} # remove "/" that is autopopulated if var was entered using tab completion (ex J006_B1/)
if ! cd $picDir; then
	echo "image directory not found"
	exit 1
fi
pipeline=${pipeline##*/}
if [ ! -f $pipeline ] ; then
	echo "Could not find the pipeline: $pipeline"
	exit 1
fi

###################### Check that files exist ###################################################

imageList="${imageSet}.txt"
if [ ! -f $imageList ] ; then
	echo "Could not find a list of images for set: $imageSet
attempting to create image list from orig_images and prob_maps directories
"
	#### create the image list
	if cd orig_images; then
		$lsCMD
	else
		echo "Could not find directory named 'orig_images'. You will have to create the image list manually. Try this command in the image directory: 
$lsCMDprint"
		exit 1
	fi
	if cd ../prob_maps; then
		$lsCMD
		cd ..
	else
		echo "Could not find directory named 'prob_maps'. You will have to create the image list manually. Try this command in the image directory: 
$lsCMDprint"
		exit 1
	fi
	cat orig_images/image_list.txt > combined_list.txt
	cat prob_maps/image_list.txt >>  combined_list.txt

	awk -F "/" '{print $NF, $0}' combined_list.txt | sort -n | cut -f2- -d' ' > $imageList
fi

### Make sure image file list doesn't have invalid entries
invalid=$(grep -i -E -v '.pnG$|.jpg$|.jpeg$|.tiff$' $imageList)
ninvalid=$(echo $invalid | wc -w)
if [ "$ninvalid" -gt 0 ]; then
	echo -n "Warning: $ninvalid files found in $imageList that do not look like they are in common image file formats. 
Continue anyways? Press 'p' to print the possibly invalid filenames (y/n/p): " 
	read -n 1 choice
	echo
	while [[ ! "$choice" =~ ^(y|n|p)$ ]]; do
		echo -n "Invalid input. Please choose y/n/p: " 
		read -n 1 choice
		echo
	done
	if [ "$choice" = "p" ]; then
		echo
		printf '%s\n' "${invalid[@]}"
		echo -n "Continue? (y/n): "
		read -n 1 choice
		echo
	fi
	if [ "$choice" = "n" ]; then
		exit 0
	fi
fi

# we know files exist, now set the other variables, make results directory
nimages=$(wc -l < $imageList)
if [ "$ilastik" = "ilastik" ] ; then 
	echo -e "\nRunning in ilastik mode. To run without ilastik prob maps, give the argument 'noilastik'"
	nimages=$((nimages / 2))         # there are 2 images in each analysis: the prob map and the original image (for the final overlay)
else
	echo "Running without ilastik prob maps. If you have prob maps, run this script with the argument 'ilastik'"
fi

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
	
	head -n $last $imageList | tail -n $batchsize > batch${first}.txt	
	cat batch${first}.txt
	cellprofiler -p $pipeline -c --file-list batch${first}.txt -o ./${resultsDir}/${first}to${last} >>cellprof.log 2>&1 &
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

rm batch*.txt

####### reorganize the ouputs using another bash script
fix_names.sh $resultsDir $imageList
# combine all results into one table
cd $resultsDir
concat_measurements.R ../$imageList $objNames

echo "Cellprofiler took $(($SECONDS / 3600))hrs, $(((SECONDS / 60) % 60))min, $((SECONDS % 60))sec"
