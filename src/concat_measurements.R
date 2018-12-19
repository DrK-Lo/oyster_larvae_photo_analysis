#!/usr/bin/env Rscript
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
  measurements$ImageNumber <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(image))          # base name no extension
  if (first){
    allMeasurements <- measurements
    first = FALSE
  }
  else{
    allMeasurements <- rbind(allMeasurements, measurements)
  }
}

write.csv(allMeasurements, file = "allmeasurements.csv", quote = FALSE)
