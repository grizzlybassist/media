#!/bin/sh
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
HOME=/home/server
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

exec 1>> $logs/ytdl-$now.log
exec 2>> $logs/ytdl-$now.log

config="$working/config/$localname-ytdl.cfg"
echo "$(date) $localname YouTube-DL Update"

yt="$downloads/YouTube"

#find $yt/videos/* -empty -type d -delete

set_variables()
{
	mkdir -pv $yt/logs
	errlog=$yt/logs/error-$now-$1.log
	tmplog=$yt/logs/$1.tmp.log
	singlelog=$yt/logs/$1.log
	count=1

	if [ -f $singlelog ]; then rm $singlelog; fi

	if [ $2 = media ]
	then
		outfold=$media/Online/$1
	elif [ $2 = sort ]
	then
		outfold=$downloads/Sort
	else
		outfold=$yt/$2/$1
	fi
	archive=$yt/archive
	mkdir -pv $outfold
	mkdir -pv $archive
}

tmp_setup()
{
	if [ -f $tmplog ]; then rm $tmplog; fi
	touch $tmplog
	exec 1>> $tmplog
	exec 2>> $tmplog
	echo "$(date)">> $tmplog
	echo "Stamp is $time">> $tmplog
	echo "$1 line $count">> $tmplog
	echo "">> $tmplog
}
err_log()
{
	echo "">> $tmplog
	echo "Ended with error code $1">> $tmplog
	echo "----------------------------------------------------------------">> $tmplog
	
	if [ $1 -gt 0 ]
	then
		cat $tmplog>> $errlog
	fi
	cat $tmplog>> $singlelog

	rm $tmplog
	
	exec 1>> $logs/ytdl-$now.log
	exec 2>> $logs/ytdl-$now.log
	
	if [ $count != NA ]
	then
		count=$((count + 1))
	fi
}

dl_subs()
{
	set_variables watchlater videos
	tmp_setup
	suberror=0
	if [ $1 = null ];
	then
		/usr/local/bin/youtube-dl -ciw -f '313+140/299+140/298+140/137+140' \
			--dateafter now-7days \
			--no-progress --add-metadata \
			--playlist-start 1 --playlist-end 20 \
			--download-archive "$archive/recents.txt" \
			--mark-watched \
			--cookies $HOME/$1.txt \
			--netrc \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(uploader)s/%(upload_date)s-%(title)s.%(ext)s" \
			"http://www.youtube.com/feed/subscriptions"
		suberror=$?
	fi

	/usr/local/bin/youtube-dl -ciw -f '313+140/299+140/298+140/137+140/bestvideo[ext=mp4]+bestaudio[ext=m4a]/22/bestvideo+bestaudio' \
		--no-progress --add-metadata \
		--download-archive "$archive/watchlater.txt" \
		--mark-watched \
		--cookies $HOME/$1.txt \
		--netrc \
		--limit-rate 80M --restrict-filenames \
		-o "$outfold/%(uploader)s/%(upload_date)s-%(title)s.%(ext)s" \
		"https://www.youtube.com/playlist?list=WL"
	
	suberror=$(($suberror+$?))
	err_log $suberror
}

dl_update_recent()
{
	set_variables $1 $2
	while read r
	do
		tmp_setup
		echo $r
		/usr/local/bin/youtube-dl -ciw -f '313+140/299+140/298+140/137+140/bestvideo[ext=mp4]+bestaudio[ext=m4a]/22' \
			--dateafter now-30days \
			--playlist-start 1 --playlist-end 30 \
			--no-progress \
			--download-archive "$archive/recents.txt" \
            --cookies $HOME/rynok86.txt \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(uploader)s/%(upload_date)s-%(title)s.%(ext)s" \
			$r
		err_log $?
	done <"$yt/lists/$1.txt"
}

dl_update_tor()
{
	echo -e 'AUTHENTICATE ""\r\nsignal NEWNYM\r\nQUIT' | nc 127.0.0.1 9051
	set_variables $1 $2
	tmp_setup
	/usr/bin/torify /usr/local/bin/youtube-dl -ciw \
		--no-progress \
		--download-archive "$archive/private.txt" \
		--limit-rate 80M --restrict-filenames \
		-o "$outfold/%(uploader)s/%(title)s.%(ext)s" \
		-a "$yt/lists/$1.txt"
	err_log $?
}

dl_update_torify()
{
	set_variables $1 $2
	while read r
	do
		tmp_setup
		echo $r
		/usr/bin/torify /usr/local/bin/youtube-dl -ciw \
			--no-progress \
			--download-archive "$archive/private.txt" \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(uploader)s/%(title)s.%(ext)s" \
			$r
		err_log $?
	done <"$yt/lists/$1.txt"
}

dl_update_all()
{
	set_variables $1 $2
	while read a
	do
		tmp_setup
		echo $a
		/usr/local/bin/youtube-dl -ciw -f '313+140/299+140/298+140/137+140/bestvideo[ext=mp4]+bestaudio[ext=m4a]/22' \
			--no-progress \
			--download-archive "$archive/recents.txt" \
            --cookies $HOME/rynok86.txt \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(uploader)s/%(title)s.%(ext)s" \
			$a
		err_log $?
	done <"$yt/lists/$1.txt"
}

dl_update_keep()
{
	set_variables $1 $2
	while read a
	do
		tmp_setup
		echo $a
		/usr/local/bin/youtube-dl -ciw -f '313+140/299+140/298+140/137+140/bestvideo[ext=mp4]+bestaudio[ext=m4a]/22/bestvideo+bestaudio' \
			--no-progress \
            --cookies $HOME/rynok86.txt \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(title)s.%(ext)s" \
			$a
		err_log $?
	done <"$yt/lists/$1.txt"
}

dl_update_keep_audio()
{
	set_variables $1 $2
	suberror=0
	while read a
	do
		tmp_setup
		echo $a
		/usr/local/bin/youtube-dl -ciw -f '313+140/299+140/298+140/137+140/bestvideo[ext=mp4]+bestaudio[ext=m4a]/22/bestvideo+bestaudio' \
			--no-progress \
            --cookies $HOME/rynok86.txt \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(title)s.%(ext)s" \
			$a
		suberror=$?
		echo $a
		/usr/local/bin/youtube-dl -ciw -f 'bestaudio[ext=m4a]' \
			--no-progress \
            --cookies $HOME/rynok86.txt \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(title)s.%(ext)s" \
			$a
		suberror=$(($suberror+$?))
	done <"$yt/lists/$1.txt"
	err_log $suberror
}

dl_update_twitch()
{
	set_variables $1 $2
	while read n
	do
		tmp_setup
		echo $n
		/usr/local/bin/youtube-dl -ciw \
			--datebefore now-1day \
			--dateafter now-30days \
			--no-progress \
			--playlist-start 1 --playlist-end 100 \
			--download-archive "$archive/$1.txt" \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(uploader)s/%(upload_date)s-%(title)s.%(ext)s" \
			$n
		err_log $?
	done <"$yt/lists/$1.txt"
}

dl_update_nonyt()
{
	set_variables $1 $2
	while read n
	do
		tmp_setup
		echo $n
		/usr/local/bin/youtube-dl -ciw \
			--no-progress \
			--playlist-start 1 --playlist-end 100 \
			--download-archive "$archive/$1.txt" \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(uploader)s/%(title)s.%(ext)s" \
			$n
		err_log $?
	done <"$yt/lists/$1.txt"
}

dl_update_private()
{
	set_variables $1 $2
	while read n
	do
		tmp_setup
		echo $n
		/usr/local/bin/youtube-dl -ciw \
			--no-progress \
			--cookies $HOME/rynok86.txt \
			--playlist-start 1 --playlist-end 100 \
			--download-archive "$archive/$1.txt" \
			--limit-rate 80M --restrict-filenames \
			-o "$outfold/%(uploader)s/%(title)s.%(ext)s" \
			$n
		err_log $?
	done <"$yt/lists/$1.txt"
}

dl_playlist()
{
	set_variables downloads downloads
}

dl_update_single()
{
	echo -e 'AUTHENTICATE ""\r\nsignal NEWNYM\r\nQUIT' | nc 127.0.0.1 9051
	set_variables $1 $2
	tmp_setup
	/usr/bin/torify /usr/local/bin/youtube-dl -ciw -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' \
		--no-progress \
		--download-archive "$archive/watchlater.txt" \
		--limit-rate 80M --restrict-filenames \
		-o "$outfold/%(uploader)s/%(title)s.%(ext)s" \
		-a "$yt/lists/$1.txt"
	err_log $?
}

dl_mp3()
{
	set_variables $1 sort
}

dl_opt()
{
	exec >/dev/tty
	continue=yes
	while [ $continue = yes ]
	do
		clear
		echo "Paste link to video below and press [ENTER]: "
		read link
		echo "$link ">> "$yt/lists/manual.txt"
		echo "Do you want to add any more videos [YES or NO]: "
		read continue
	done
	clear
	dl_single manual watchlater
	rm "$yt/lists/manual.txt"
}

if [ $# -eq 0 ]
then
	act=list
else
	act=$1
fi

if [ $act = downloads ]
then
	dl_opt
elif [ $act = netrc ] && [ -r $working/config/$2 ] && [ ! -f /tmp/ytdl-sub.pause ]
then
    touch /tmp/ytdl-sub.pause
	echo Authenticating YouTube with file $working/config/$2
    if [ ! -f $HOME/.netrc ]
    then
        cp $working/config/$2 $HOME/.netrc
        chown server $HOME/.netrc
        chmod 600 $HOME/.netrc
    fi
	dl_subs $2
    rm /tmp/ytdl-sub.pause
elif [ $act = list ] && [ ! -f /tmp/ytdl.pause ]
then
	echo "Running list subscriptions"
	touch /tmp/ytdl.pause
    groups=`cat $config | awk '{print $1}' | tr "\n" " "`
    for s in ${groups}
    do
	if [ ! -f /tmp/ytdl-$s.pause ]
	then
        if [ ! -f $HOME/.netrc ]
        then
            cp $working/config/rynok86 $HOME/.netrc
            chown server $HOME/.netrc
            chmod 600 $HOME/.netrc
        fi
		touch /tmp/ytdl-$s.pause
		dltype=`grep $s $config | awk '{print $2}'`
		stor=`grep $s $config | awk '{print $3}'`
		echo $s
		dl_update_$dltype $s $stor
		rm /tmp/ytdl-$s.pause
	fi
    done
	rm /tmp/ytdl.pause
elif [ -f /tmp/ytdl.pause ]
then
	echo "Unable to run list subscriptions due to pause existing"
fi
#if [ ! -f /tmp/ytld*pause ]; then rm $HOME/.netrc; fi