#!/bin/sh

command -v run_ilastik.sh >/dev/null 2>&1 || { echo >&2 "Ilastik is required. Aborting. If you have ilastik installed already, try adding run_ilastik.sh to your path"; exit 1; }
ILASTIK='run_ilastik.sh'

if [ $# -eq 0 ] ; then
	echo
	echo "run_ilastik_for_cellp.sh takes two named arguments -f/--file and -p/--project. 

Ex: run_ilastik_for_cellp.sh -f orig_images/* -p ilastik_pipe.ilp"
	echo
	exit
fi
############ Argument Parser ######################################
PARAMS=""
FILEARG=()
while (( "$#" )); do 
	case "$1" in 
	  -f|--file)
	    shift
	    while (( "$#" )); do # loop through every var after file flag      
	    	if [ "$1" == "-p" ] || [ "$1" == "--project" ]; then # exit the loop if project flag is encountered
			break
		fi
		FILEARG+=($1)     # add vars to array
	    	shift
	    done
	    ;;
	  -p|--project)
	    PROJARG=$2
	    shift 2
	    ;;
	  --)   # end argument parsing
	    shift
	    break
	    ;;
	  -*|--*=) # unsupported flags
	    echo "Error: unsupported flag $1" >&2
	    exit 1
	    ;;
	  *) # preserve positional arguments
	   PARAMS="$PARAMS $1"
	   shift
	esac	  
done
eval set -- "$PARAMS"
##########################################################################
$ILASTIK --headless --project=${PROJARG} ${FILEARG[@]} --output_format=tif --export_dtype=uint16 --output_axis_order="cyx" --pipeline_result_drange="(0.0,1.00)" --export_drange="(0,65535)" --output_filename_format=./prob_maps/{nickname}_results.tif ; then


