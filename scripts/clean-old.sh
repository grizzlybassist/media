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

#exec 1>> $logs/clean-$now.log
#exec 2>> $logs/clean-$now.log

config="$working/config/$localname-clean.cfg"
echo "$(date) $localname Clean folders"

del()
{
	echo "$video $1"
	#rm -r -f $1
}

test_file()
{
	#echo $1 >> $logs/file-test.log
	ext=${1##*.}
	ext="$(echo $ext | tr '[A-Z]' '[a-z]')"
	if [ $ext = mp4 ]; then video=$((video + 1)); fi
	if [ $ext = webm ]; then video=$((video + 1)); fi
	if [ $ext = mkv ]; then video=$((video + 1)); fi
	if [ $ext = mts ]; then video=$((video + 1)); fi
	if [ $ext = mpg ]; then video=$((video + 1)); fi
	if [ $ext = m4v ]; then video=$((video + 1)); fi
	if [ $ext = avi ]; then video=$((video + 1)); fi
	if [ $ext = m4a ]; then video=$((video + 1)); fi
	if [ $ext = part ]; then video=$((video + 1)); fi
	#echo $ext >> $logs/file-test.log
	#echo "$video 0" >> $logs/file-test.log
}

clean()
{
	for v in "$1"/*
	do
		if [ -d "$v" ]; then test_folder "$v"; fi
	done
	cd "$1"
}

test_folder()
{
	video=0
	for f in "$1"/*
	do
		if [ -d "$f/sample" ]; then del "$f/sample"; fi
		if [ -d "$f/Sample" ]; then del "$f/Sample"; fi
		if [ -d "$f/SAMPLE" ]; then del "$f/SAMPLE"; fi
		if [ -d "$f" ]; then test_folder "$f"; elif [ -f "$f" ]; then test_file "$f"; fi

		#echo "$video $1"
	done
	if [ $video -eq 0 ]; then del "$1"; fi
}

if [ $# -eq 1 ]
then
	clean "$1"
else
	fold=`cat $config | awk '{print $1}' | tr "\n" " "`
	for s in ${fold}
	do
		clean $s
	done
fi
