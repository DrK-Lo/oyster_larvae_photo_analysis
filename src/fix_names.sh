#!/bin/sh

if [ $# -ne 1 ] ; then
	echo "Error: you must supply the directory that contains the results as input" 1>&2
	exit 1
fi

parentDir=$1
cd $parentDir

for dir in *to*; do  
	cd $dir
	filename=(*.png)
	filename="${filename%overlay.png}"
	for f in *.csv; do
		mv $f "${filename}_$f";
	done
	cd .. 
done

mkdir -p overlays
mkdir -p measurements

mv */*.png overlays
mv */*filtered_shells.csv measurements
rm -rf [0-9]*to*[0-9]
