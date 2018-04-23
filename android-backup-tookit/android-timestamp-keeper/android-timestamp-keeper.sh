#!/bin/bash
# android-timestamp-keeper v3.1
# Developed by dragomerlin, 30/07/2017
# Put this script inside the phone, for example under /sdcard/
# Timestamps go in timestamps.txt next to the script.
# It parses recursively from the specified directory.
# Paths are relative to android-timestamp-keeper.sh
#  is optional but recommended. If you don't have  on android use the epoch time.
# Root is required to write the timestamps, but not to read them.
# You can check for process com.android.systemui to detect android.
# Bash is required since sh doesn't have the [[ builtins. On android it's sh which is really bash.
# Usage:
# 	bash android-timestamp-keeper.sh read directory
#	bash android-timestamp-keeper.sh write directory
#
# Warning: to work properly on android it requires , however the "date" version included with
#  can mess things up with other android software, so if you experience problems with Play Store
# or connectivity uninstall . There are two great versions on of it on the Play Store, one from
# Stericson and the other from Robert Nediyakalaparambil (this latest one doesn't have uninstaller, so
# use the Stericson version to uninstall it).
#
# There's an android native app which requires root, but the txt format is different
# https://play.google.com/store/apps/details?id=br.com.pogsoftwares.filetimestamp

# Examples
# Backup the timestamps of whole internal sdcard (relative to it).
# Better use relative paths to use from the computer also:
#	bash android-timestamp-keeper.sh read .
# Restore previous timestamps (timestamps.txt is parsed):
#	bash android-timestamp-keeper.sh write .

# Correct usage, example with epoch time 1357132455 (2 January 2013 at 13:14:15 UTC):
# - Cygwin (for Windows):  
#		touch -c -t 201301021314.15 picture.png
# - Android (with touch from  from Stericson):
#		 touch -c -t 201301021314.15 picture.png
# - Some stock roms like the Samsung Galaxy S2 include a touch version that works
#	only with epoch. You will know it because the touch --h shows
#	touch: usage: touch [-alm] [-t time_t] <file>
#		touch -t 1357132455 picture.png
# - Linux (ubuntu): works both ways,  may be present or not:
#		[] touch -c -t 201301021314.15 picture.png
# - BSD: better install  on it for stat and touch.
# - MAC (OS X): last modification time is shown in epoch or text
#		stat -f %N somefile
#		stat -f %m somefile
#		stat -f "%Sm" -t "%Y%m%H%M.%S" picture.png
#		touch -c -t 201301021314.15 picture.png

# TODO:
# Improve timestamps file management

command -v busybox >/dev/null 2>&1 || { echo >&2 "busybox is required"; exit 1; }
command -v find >/dev/null 2>&1 || { echo >&2 "find is required"; exit 1; }
#command -v touch >/dev/null 2>&1 || { echo >&2 "touch is required"; exit 1; }
command -v sed >/dev/null 2>&1 || { echo >&2 "sed is required"; exit 1; }
command -v ps >/dev/null 2>&1 || { echo >&2 "ps is required"; exit 1; }
#command -v pgrep >/dev/null 2>&1 || { echo >&2 "pgrep is required"; exit 1; }

# root detection can become very tricky depending on operating system
# weroot=0
# if [[ $(id -u) == *root* ]]
# then
	# weroot=1
# fi
# if [ "$(id -u)" == "0" ]
# then
	# weroot=1
# fi
# if [ "$( id -u)" == "0" ]
# then
	# weroot=1
# fi
# if [[ weroot -ne 0 ]]
# then
	# echo "This script must be run as root" 1>&2
	# exit 1
# fi

cname=0
cdate=0

if [[ -z $1 ]] || [[ -z $2 ]] || ( [ "$1" != "read" ] && [ "$1" != "write" ] )
	then
	echo "Usage: sh android-timestamp-keeper.sh [read/adjust/write] directory"
	echo "Timestamps go in timestamps.txt"
	exit 0;
fi

# Check if working dir exists and it's not a symlink
if [[ -d "$2" && ! -L "$2" ]] ; then
	# Put one trailing slash for dirs in case there's more than one or none
	# Required to concatenate path strings
	WDIR=`echo $2 | busybox sed -e "s,/\+$,,"`"/"
    echo "Working on dir: $WDIR"
else
	echo "Missing directory: $2"
	exit 1
fi


# if [ $1 = "read_epoch" ]
	# then
	# if [[ -f "timestamps.txt" ]]
	# then
		# rm timestamps.txt
	# fi
	# find "$2" -type f -exec stat -c %n {} > timestamps.txt \; -exec stat -c %Y {} > timestamps.txt \;
# fi

# if [ $1 = "read_yyyymmddhhmmss" ]
	# then
	# if [[ -f "timestamps.txt" ]]
	# then
		# rm timestamps.txt
	# fi
	# if [[ -f "temporallisting.txt" ]]
	# then
		# rm temporallisting.txt
	# fi
	# find "$2" -type f -exec echo {}>>temporallisting.txt \;
	
	# while read line
	# do
		# stat -c %y "$line"
	# done < temporallisting.txt
# fi


##################################
# On android we could use ' stat' but the default works well
if [ "$1" = "read" ]
	then
	if [[ -f "timestamps.txt" ]]
	then
		rm timestamps.txt
	fi
#	This was to remove leading ./ when running "find ."
#	(cd $WDIR; find . -type f -exec sh -c ' stat -c %n "{}" | sed -e "s/^\.\///g" ' \; -exec  stat -c %Y "{}" \; -exec sh -c ' stat -c %y "{}" | sed -e 's/-//g' | sed -e 's/://g' | sed -e "s/ //g" | cut -d '.' -f1 | sed "s/./.&/13" ' \;) >> timestamps.txt
	# Store relative paths to the input folder, not from script location.
	(cd "$WDIR"; busybox find . -type f -exec busybox stat -c %n "{}" \; -exec busybox stat -c %Y "{}" \; -exec busybox stat -c %y "{}" \;) >> timestamps.txt
	
	#	It's done this way because -exec can have issues with nested commands (see stamps-v2.4.sh it's done differently)
	count=1
	while read line
	do
		if [ $(( $count % 3 )) -eq 0 ]
		then
			# echo "line is ${line}"
			# This greatly reduces the number or write operations
			newline="$(echo "$line" | busybox sed 's/-//g' | busybox sed 's/://g' | busybox sed 's/ //g' | busybox sed 's/\..*//' | busybox sed 's/./.&/13')"
			busybox sed -i "${count}s/.*/${newline}/g" timestamps.txt
			# echo "newline is ${newline}"
			# busybox sed -i "${count}s/-//g" timestamps.txt
			# busybox sed -i "${count}s/://g" timestamps.txt
			# busybox sed -i "${count}s/ //g" timestamps.txt
			# busybox sed -i "${count}s/\..*//" timestamps.txt
			# busybox sed -i "${count}s/./.&/13" timestamps.txt
		fi
		((count++))
	done <timestamps.txt
	
fi
##################################


##################################
if [ "$1" = "write" ]
then
	if [ ! -f timestamps.txt ]
	then
		echo "timestamps.txt does not exist on current dir"
		exit 0
	fi
	
	count=0
	
	while read line
	do
		if [[ count -eq 0 ]]
		then
			NAME=$line
		fi
		if [[ count -eq 1 ]]
		then
			EPOCH=$line
		fi
		if [[ count -eq 2 ]]
		then
			MODDATE=$line
		fi
		
		# Time to write
		if [[ count -eq 2 ]]
		then
			if [[ -f "$WDIR$NAME" ]]
			then
				#  is present
				if  &> /dev/null
				then
					(cd "$WDIR" ; busybox touch -c -t "$MODDATE" "$NAME")
				else
					#  not present (shouldn't be android)
					#echo "PATH is" "$WDIR$NAME"
					(cd "$WDIR" ; busybox touch -c -t "$MODDATE" "$NAME")
				fi
			else
				echo "File" \"$WDIR$NAME\" "doesn't exist. Skipping."
			fi
		

		fi

		# Update counter
		if [[ count -eq 2 ]]
		then
			count=0
		else
			((count++))
		fi
		
		#echo $FILENAME
	done <timestamps.txt
	
fi
##################################


# if [ $1 = "write_android" ]
# then
	# if [ ! -f timestamps.txt ]
	# then
		# echo "timestamps.txt does not exist on current dir"
		# exit 0
	# fi
	# count=0
	# while read line
	# do
		# if [[ count -eq 0 ]]
		# then
			# NAME=$line
			##echo Name=$NAME
			# count=1
		# else
			# MODDATE=$line
			##echo Mod=$MODDATE
			# count=0
			# if [[ -f $NAME ]]
			# then
				# touch -m -t ${MODDATE} ${NAME}
			# else
				# echo "File" \"$NAME\" "doesn't exist. Skipping."
			# fi
		# fi
	# done <timestamps.txt
# fi

# if [ $1 = "write_linux" ]
# then
	
	# if [ ! -f timestamps.txt ]
	# then
		# echo "timestamps.txt does not exist on current dir"
		# exit 0
	# fi
	# count=0
	# while read line
	# do
		# if [[ count -eq 0 ]]
		# then
			# NAME=$line
			##echo Name=$NAME
			# count=1
		# else
			# MODDATE=$line
			##echo Mod=$MODDATE
			# count=0
			# if [[ -f $NAME ]]
			# then
				# LINUXDATE=$(date -d @$MODDATE '+%Y%m%d%H%M.%S')
				# touch -t $LINUXDATE ${NAME}
			# else
				# echo "File" \"$NAME\" "doesn't exist. Skipping."
			# fi
		# fi
	# done <timestamps.txt
# fi
