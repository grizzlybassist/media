#!/bin/sh
SHELL=/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
localname=`hostname`
unraid="/mnt/unraid"
working="$unraid/Cronjobs/media"
media="$unraid/Media"
downloads="$unraid/Downloads"

time=$(date +"%Y-%m-%d.%H%M")
now=$(date +"%Y-%m-%d")
day=$(date +"%d")
month=$(date +"%Y-%m")
year=$(date +"%Y")
logs="$working/logs"
mkdir -p $logs

#exec 1>> $logs/ffmpeg-$now.log
#exec 2>> $logs/ffmpeg-$now.log

config="$working/config/$localname-h265ize.cfg"
echo "$(date) $localname ffmpeg h.265 conversion Update"

h265ize()
{
	if [ ! -n "$(find "$1" -maxdepth 0 itype d -empty 2>/dev/null)" ]
	then
		find "$1" -mindepth 2 -type f -print0 | xargs -0 mv -vn -t "$1"
		find "$1"/* -empty -type d -delete
		
		mkdir -p "$2"
		for i in "$1"/*
		do
			path="${i%/*}"
			filename=$(basename -- "${i%.*}")
			extension="${i##*.}"
			old="$i"
			new="$2/$filename-$change.mkv"
			if [ -e "$old" ] && [ ! -e "$new" ]
			then
				docker run --cpu-shares=100 --rm -v $1:$1 -v $2:$2 jrottenberg/ffmpeg \
				-hide_banner -i "$old" \
				-c:v $video -c:a $audio \
				-c:s copy -map 0 "$new" -async 1 -vsync 1
				if [ $? -eq 0 ]
				then
					mkdir -p "$2/archive"
					mv -vn "$i" -t "$2/archive/"
				else
					if [ -e "$new" ]; then rm "$new"; fi
				fi
			fi
		done
	fi
	
	if [ ! -n "$(find "$2" -maxdepth 0 itype d -empty 2>/dev/null)" ]; then find "$2"/* -empty -type d -delete; fi
}

if [ "$1" = video ] || [ "$2" = video ]
then
	video="libx265 -preset fast -tune grain -crf 21 -pix_fmt yuv420p10"
	audio=copy
	change=h265
elif [ "$1" = audio ] || [ "$2" = audio ]
then
	video=copy
	audio="ac3 -b:a 384k"
	change=h265
elif [ "$1" = both ] || [ "$2" = both ]
then
	video="libx265 -preset fast -tune grain -crf 21 -pix_fmt yuv420p10"
	audio="ac3 -b:a 384k"
	change=h265
elif [ "$1" = flac ] || [ "$2" = flac ]
then
	video="libx265 -preset fast -tune grain -crf 21 -pix_fmt yuv420p10"
	audio=flac
	change=h265
elif [ "$1" = ac3 ] || [ "$2" = ac3 ]
then
	video="libx265 -preset fast -tune grain -crf 21 -pix_fmt yuv420p10"
	audio="ac3 -b:a 384k"
	change=h265
elif [ ! -d "$1" ] && [ $# -gt 0 ]
then
	video="libx265 -preset fast -tune grain -crf 21 -pix_fmt yuv420p10"
	audio="$1"
	change=h265
elif [ ! -d "$2" ] && [ $# -gt 1 ]
then
	video="libx265 -preset fast -tune grain -crf 21 -pix_fmt yuv420p10"
	audio="$2"
	change=h265
else
	echo "No ffmpeg arguments given"
	wait 30
	exit
fi

if [ -d "$1" ]
then
	convert="$1"
	converted="$1/Converted"
elif [ -d "$2" ]
then
	convert="$2"
	converted="$2/Converted"
elif [ "$1" = video ] || [ "$2" = video ]
then
	convert="$downloads/Convert/video"
	converted="$downloads/Converted"
elif [ "$1" = audio ] || [ "$2" = audio ]
then
	convert="$downloads/Convert/audio"
	converted="$downloads/Converted"
elif [ "$1" = both ] || [ "$2" = both ]
then
	convert="$downloads/Convert/both"
	converted="$downloads/Converted"
else
	echo "No folder arguments given"
	wait 30
	exit
fi

h265ize $convert $converted

#docker rm $(docker ps -a | grep "ffmpeg" | awk "{print \$1}")