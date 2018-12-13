#!/usr/bin/env Rscript
################################################################
# File    : concat_measurements.R
# History : 12-12-2018 Created by Kevin Freeman (KF)
################################################################
#
# This script goes into all the folders of results from the
# images in the image list, finds the measurements.csv file,
# and creates a new file 'allmeasurements.csv' by binding
# all the separate measurements files together by row
#
# Inputs : imagelist.txt objectname
#
# objectname is whatever name you gave to the object that you
# measured in cellprofiler (ex: eggs)
#
# Outputs : allmeasurements.csv
#
################################################################


args = commandArgs(trailingOnly=TRUE)
if (length(args)!=2) {
  stop("2 arguments required. Usage: Rscript concat_measurments.R image_list.txt objectname", call.=FALSE)
}
objectname <- args[2]
imageList  <- file(args[1], open = "r")
images     <- readLines(imageList)

first <- TRUE
for (image in images){
  print(image)
  measurements <- read.csv(paste0(basename(image), "/measurements_",objectname, ".csv"), header = TRUE, sep = ",")
  # change image number column from a number to something more descriptive
  measurements$ImageNumber <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(image))       # base name of image file with no extension
  if (first){
    allMeasurements <- measurements
    first = FALSE
  }
  else{
    allMeasurements <- rbind(allMeasurements, measurements)
  }
}

write.csv(allMeasurements, file = "allmeasurements.csv", quote = FALSE)
