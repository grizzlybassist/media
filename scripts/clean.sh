#!/bin/sh
SHELL=/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
localname=`hostname`
unraid="/mnt/unraid"
working="$unraid/Cronjobs/media"
media="$unraid/Media"
downloads="$unraid/Downloads"

now=$(date +"%Y-%m-%d")
day=$(date +"%d")
month=$(date +"%Y-%m")
year=$(date +"%Y")
logs="$working/logs"
mkdir -p $logs

exec 1>> $logs/clean-$now.log
exec 2>> $logs/clean-$now.log

config="$working/config/$localname-clean.cfg"
echo "$(date) $localname Clean folders"

del()
{
	#echo "delete $1"
	rm -rf "$1"
}

clean()
{
	for v in "$1"/*
	do
		if [ -d "$v" ]; then prep_folder "$v"; fi
	done
	cd "$1"
}

prep_folder()
{
	#find "$1" -iname "*.jpg" | while read file; do del "$file"; done
	#find "$1" -iname "*.nfo" | while read file; do del "$file"; done
	find "$1" -empty -type d | while read file; do del "$file"; done
	
	for f in "$1"/*
	do
		if [ -d "$f/sample" ]; then del "$f/sample"; fi
		if [ -d "$f/Sample" ]; then del "$f/Sample"; fi
		if [ -d "$f/SAMPLE" ]; then del "$f/SAMPLE"; fi
		test_folder "$f"
	done
}

test_folder()
{
	if [ -d "$1" ] && [ ! -z "$(ls -A "$1")" ]; then prep_folder "$1"; fi

	video=$(find "$1" -iname "*.mp4" -or -iname "*.mkv" -or -iname "*.webm" -or -iname "*.mts" -or -iname "*.mpg" -or -iname "*.m4v" -or -iname "*.mov" -or -iname "*.avi" -or -iname "*.m4a")
	if [ "$video" = "" ] && [ -d "$1" ]; then del "$1"; fi
}

if [ $# -eq 1 ]
then
	test_folder "$1"
else
#	folds=`cat $config | awk '{print}' | tr "\n" "\0"`
#	for s in ${folds}
	for s in `tr '\n' '\0' < $config | xargs -0`
	do
		test_folder $unraid/"$s"
	done
fi
