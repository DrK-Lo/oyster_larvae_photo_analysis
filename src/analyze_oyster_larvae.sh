#!/usr/bin/bash
### make sure user provided a folder of images
usage="\nUsage :\n\n$ analyze_oyster_larvae.sh [zip file/directory]\n"
if [ $# -ne 1 ]; then
	echo -e $usage
	exit 1
fi

zipFile=$1
imageSet="${zipFile%.zip}" || imageSet="$zipFile" 

ilastikPipeline="generate_prob_maps.ilp"
cellpPipeline="analyze_prob_maps.cppipe"
# check that the variables are good
if [ ! -f $ilastikPipeline ]; then
	echo "Could not find pipeline : ${ilastikPipeline}, make sure it is in the current directory. Edit the script to use a different pipeline"
fi
if [ ! -f $cellpPipeline ]; then
	echo "Could not find pipeline : ${cellpPipeline}, make sure it is in the current directory. Edit the script to use a different pipeline."
fi
if [ ! -e $zipFile ]; then
	echo -e $usage
	exit 1
fi
## unzip if needed, move to and setup directories
if [ $zipFile != $imageSet ]; then
	unzip $zipFile -d $imageSet -x / 
fi

cd $imageSet
mkdir orig_images
mv *.png orig_images


# analysis
if run_ilastik_for_cellp.sh -p ../${ilastikPipeline} -f orig_images/* ; then
	runCellProfilerParallel.sh $imageSet ../${cellpPipeline} 
fi

