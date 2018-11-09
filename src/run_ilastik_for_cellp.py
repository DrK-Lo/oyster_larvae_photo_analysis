#!/
# coding: utf-8

# In[ ]:


import argparse
import subprocess
import shutil
import sys

######################################################
#
# File   : run_ilastik_for_cellp.py
# History: 11-9-2018 - Created by Kevin Freeman (KF)
#
######################################################
#
# This script is meant to be a more robust version
# of the bash script I wrote with the same name.
# It constructs a call to ilastik based on the 
# given image files and project file
#
######################################################

shutil.which("run_ilastik.sh") is not None or sys.exit("Could not find run_ilastik.sh. Check that it is in your path and executable")

parser = argparse.ArgumentParser()
parser.add_argument('--file', '-f', nargs = "+", required = True)
parser.add_argument('--project', '-p', required = True)

args = parser.parse_args()

stdArgs = ["--output_format=tif",  "-export_dtype=uint16", "--output_axis_order=cyx", 
"--pipeline_result_drange=[0.0,1.00]", "--export_drange=(0,65535)", 
"--output_filename_format=./prob_maps/{nickname}_results.tif"]

subprocess.call(['run_ilastik.sh', '--headless', '--project=' + args.project] + args.file + stdArgs)

