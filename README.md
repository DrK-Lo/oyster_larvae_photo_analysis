# oyster_larvae_photo_analysis
CellProfiler for oyster larvae pictures


## measure_oysters_pipeline.cppipe

This pipeline is tuned to segment out oyster larvae from a green background that may have some clutter. It can be loaded directly into the CellProfiler GUI to be modified or be run from the command line using the command `cellprofiler -p measure_oysters_pipeline.cppipe` followed by images that need to be analyzed. Currently the only output is images with the edges of the larvae tissue outlined in red and the edges of the larvae shell outlined in yellow. It should be easy to modify to output various measurements for the larvae.

## runCellProfilerParallel.sh

CellProfiler is optimized to run on a single core when it is being run headless. This script parallelizes running a CellProfiler pipeline on a large list of images. Variables are set at the top of the script and should be modified based on the analysis.


Inputs:

	- imageList : a list of the absolute paths of all the images to be analyzed. An easy command for generating this list from a directory of images is included in a comment at the top of the script. 
		      Just type `head runCellProfilerParallel.sh` and copy the commmand from the output.
	- pipeline  : name of the pipeline to be run. Include the path if it is not in your working directory.
	- batchsize : number of images to run at one time on one CPU
	- ncpu      : number of CPUs to use

#### Choosing batch size and ncpu

Running "measure_oysters_pipeline" on one image takes approximately 2min. If you set the batch size to 1 and ncpus to the number of images being analyzed, all images will be analyzed simulataneously and the entire analysis will take 2min. If you have more images to analyze than cpus available, it will save time to increase the batch size to = number of images / number of available CPUs. Running larger batches of images uses more memory however, so with very large amounts of images it may be a good idea to limit the size of your batches.
