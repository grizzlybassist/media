#!/bin/sh
SHELL=/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
localname=`hostname`
unraid="/mnt/unraid"
archive="/mnt/unraid/Archive"
working="$unraid/Cronjobs/media"
media="$unraid/Media"
downloads="$unraid/Downloads"

now=$(date +"%Y-%m-%d")
day=$(date +"%d")
month=$(date +"%Y-%m")
year=$(date +"%Y")
logs="$working/logs"
mkdir -p $logs

exec 1>> $logs/pics-$month.log
exec 2>> $logs/pics-$month.log

config="$working/config/$localname-pictures.cfg"
echo "$(date) $localname Sorting Pictures"

piccfg="$working/config/picture-types.cfg"
movcfg="$working/config/movie-types.cfg"
monthnames=( invalid January February March April May June July August September October November December )

#1=input file 2=dest folder 3=fullname
move_file()
{
	input="$1"
	dest="$2"
	name="${3%.*}"
	ext="${3##*.}"
	mkdir -pv "$dest"
	new="$2/$name.$ext"

	if [ -f "$new" ];
	then
		count=1
		while [ -f "$dest/$name ($count).$ext" ];
		do
			count=$(( $count + 1 ))
		done
		mv -v --backup=t "$input" "$dest/$name ($count).$ext"
	else
		mv -v --backup=t "$input" "$new"
	fi
}

#1=input file 2=dest folder
to_folder()
{
	input="$1"
	dest="$2"
	mkdir -pv "$dest"
	fullname="${1##*/}"

	move_file "$input" "$dest" "$fullname"
}

#1=input file 2=dest file
to_file()
{
	input="$1"
	dest="${2%/*}"
	fullname="${2##*/}"

	move_file "$input" "$dest" "$fullname"
}

#1=input file 2=dest file
move_pic()
{
	input="$1"
	infold="${1%/*}"
	dest="${2%/*}"
	fullname="${2##*/}"
	name="${fullname%.*}"
	ext="${fullname##*.}"

	if test -e "$2" && test -e "$1";
	then
		diff=`compare -metric phash "$1" "$2" null: 2>&1`
		if [ $diff == 0 ]; then to_folder "$1" "$infold/trash"; fi
	fi

	if test -e "$dest/$name (1).$ext" && test -e "$1";
	then
		count=1
		while test -e "$dest/$name ($count).$ext" && test -e "$1";
		do
			diff=`compare -metric phash "$1" "$dest/$name ($count).$ext" null: 2>&1`
			if [ $diff == 0 ]; then to_folder "$1" "$infold/trash"; fi
			count=$(( $count + 1 ))
		done
	fi

	if test -e "$1";
	then
		to_file "$1" "$2"
	fi
}

#1=input folder 2=output folder
prep_folders()
{
	if [ "$(ls $1)" ];
	then
		mkdir -pv "$archive/Photo-Uploads/$now"
		mkdir -pv "$2/.sort"
		cp -Rvn "$1/"* "$archive/Photo-Uploads/$now"
		mv -vn "$1/"* "$2/.sort"
	fi

	if [ "$(ls -A $2)" ];
	then
		find "$2/.sort" -type f -print0 | xargs -0 mv -vn -t "$2/.sort"
	fi
}

#1=sort folder
move_invalid()
{
	if [ "$(find "$1/.sort" -maxdepth 1 -type f)" ];
	then
		mkdir -pv "$1/.sort/invalid"
		mv -v --backup=t "$1/.sort/"*.* "$1/.sort/invalid"
	fi
}

#1=folder to be cleaned
clean_folder()
{
	if [ "$(ls $1)" ];
	then
		find "$1" -empty -type f -delete
		find "$1/"* -empty -type d -delete
	fi
}

#1=input file #2=input folder 3=dest folder 4=output ext
sort_movie()
{
	mkdir -pv "$3/Videos"
	to_folder "$1" "$3/Videos"
}

#no input, relies on dateorig
def_jname()
{
#	echo ${dateorig[*]}
	jsecond=${dateorig[5]}
	jminute=${dateorig[4]}
	jhour=${dateorig[3]}
	jday=${dateorig[2]}
	jmonth=${dateorig[1]}
	imonth=$(echo $jmonth | sed 's/^0*//')
	jyear=${dateorig[0]}
	monthname=${monthnames[${imonth}]}

	datepath=$jyear/$jmonth-$monthname
#	jname=$(echo ${dateorig[@]} | sed 's% %-%g')
	jname="$monthname $jday, $jyear at $jhour.$jminute.$jsecond"
}

#1=input file 2=input folder 3=dest folder 4=output ext
sort_picture()
{
	error=0
	declare -a dateorig=($(identify -verbose "$1" | grep DateTimeOri | awk '{print $2,$3}' | sed 's%:% %g' | sed 's%-% %g' | sed 's%T% %g'))

	def_jname

	if [ "$monthname" == "invalid" ];
	then
		declare -a dateorig=($(identify -verbose "$1" | grep date:mod | awk '{print $2}' | sed 's%:% %g' | sed 's%-% %g' | sed 's%T% %g'))
		def_jname
		if [ "$4" != "png" ];
		then
			mkdir -pv "$2/invalid"
			move_pic "$1" "$2/invalid/$jname.$4"
			return 1
		fi
	fi
#	if [ "$monthname" == "invalid" ];
#	then
#		mkdir -pv "$2/invalid"
#		to_folder "$1" "$2/invalid"
#		return 1
#	fi

	if ! test -w "$3/$datepath";
	then
		mkdir -pv "$3/$datepath"
	fi

	move_pic "$1" "$3/$datepath/$jname.$4"

}

#1=action 2=input folder 3=dest folder 4=output ext 5=old ext
sort_type()
{
	for fil in $2/*.$5
	do
		if test -e "$fil";
		then
			sort_$1 "$fil" "$2" "$3" "$4"
		fi
	done
}

#1=input folder 2=dest folder
sort_files()
{
	if [ -d "$1/.sort" ]
	then
		mv "$1/.sort" "$2"
	fi

	prep_folders "$1" "$2"

	ptypes=`cat $piccfg | awk '{print $1}' | tr "\n" " "`
	for p in ${ptypes}
	do
		pext=`grep $p $piccfg | awk '{print $2}'`
		sort_type picture "$2/.sort" "$2" $pext $p
	done
	mtypes=`cat $movcfg | awk '{print $1}' | tr "\n" " "`
	for m in ${mtypes}
	do
		mext=`grep $m $movcfg | awk '{print $2}'`
		sort_type movie "$2/.sort" "$2" $mext $m
	done

	if [ -d "$2/.sort" ]
	then
		mv "$2/.sort" "$1"
	fi

	clean_folder "$1"
	clean_folder "$2"
	clean_folder "$1/.sort"
}

#1=input folder 2=dest folder
begin_sort()
{
	if [ "$(ls $1)" ]
	then
		sort_files $1 $2
	elif [ -d "$1/.sort" ]
	then
		if [ "$(ls $1/.sort)" ]
		then
			sort_files $1 $2
		fi
	fi
}

#1=input folder 2=dest folder
if [ $# -ge 2 ];
then
	begin_sort $1 $2
else
	folds=`cat $config | awk '{print $1}' | tr "\n" " "`
	for f in ${folds}
	do
		stor=`grep $f $config | awk '{print $2}'`
		mkdir -pv $f
		mkdir -pv $stor
		begin_sort $f $stor
		mkdir -pv $f
	done
	rclone move kilefam-db:/Camera\ Uploads/ $unraid/kilefam/Dropbox/Camera\ Uploads/kilefam
	rclone move ryankile-db:/Camera\ Uploads/ $unraid/kilefam/Dropbox/Camera\ Uploads/rynok86
	rclone move kilefam-gd:/Google\ Photos/ $unraid/kilefam/Dropbox/Google\ Photos/kilefam/
	rclone move rynok86-gd:/Google\ Photos/ $unraid/kilefam/Dropbox/Google\ Photos/rynok86/
	rclone sync --delete-excluded --exclude Private/ --exclude Videos/ $unraid/Photos/ kilefam-db:/Photos/
	rclone sync --delete-excluded --exclude Private/ $unraid/Photos/ kilefam-gd:/Photos/
fi