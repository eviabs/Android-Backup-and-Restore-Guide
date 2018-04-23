###############################################################
#
# Name: ADB Backup Splitter (non extraction method)
# Author: dragomerlin
# License: GPL v3
#
###############################################################
#
# Description:
#
# This bash script utility reads an adb backup, and for each android app or sdcard (shared) inside,
# creates a single backup of its own into a folder. So basically is useful for
# splitting one big unmanageable file into little ones, so you can store or restore android apps 
# or sdcards individually. Because, as we know, adb restore does not allow for any kind of selection
# at restore time, it just does all at once.
# The resulting ab(s) go into the split-android/. This script works on Cygwin also. Should work on OS X too.
# The goodness of this method is that thanks to the capabilities of
# tar-binary-splitter it splits a tar archive without actually extracting
# the contents to the hard drive and then re-archiving. Thus there's no issue
# even if there are incompatible characters in the filename or path.
# This is the recommended method for splitting an adb backup.
#
# Creating a backup with -shared flag has known issues (corruption),
# so is not recommended. Use the flag -noshared
#
# Sometimes, using the flag -nocompress can help when this errors happen on logcat:
# 02-01 20:15:26.961  3758 22126 D BackupManagerService: Binding to full backup agent : com.example
# 02-01 20:15:26.987  3758 22126 D BackupManagerService: awaiting agent for ApplicationInfo{e6e6d23 com.example}
# 02-01 20:15:27.173  3758  5719 D BackupManagerService: agentConnected pkg=com.example agent=android.os.BinderProxy@bca7efe
# 02-01 20:15:27.174  3758 22126 I BackupManagerService: got agent android.app.IBackupAgent$Stub$Proxy@e5da65f
# 02-01 20:15:27.175  3758 25265 D BackupManagerService: Writing manifest for com.example
# 02-01 20:15:27.176  3758 25265 D BackupManagerService: Calling doFullBackup() on com.example
# 02-01 20:15:27.176  3758 25265 V BackupManagerService: starting timeout: token=1345547b interval=300000 callback=com.android.server.backup.BackupManagerService$PerformAdbBackupTask@19db723
# 02-01 20:20:27.277  3758  5050 V BackupManagerService: TIMEOUT: token=1345547b
# 02-01 20:20:27.277  3758  5050 V BackupManagerService:    Invoking timeout on com.android.server.backup.BackupManagerService$PerformAdbBackupTask@19db723
# 02-01 20:20:27.277  3758  5050 W BackupManagerService: adb backup timeout of PackageInfo{3b3574a com.example}
# 02-01 20:20:27.279  3758  5050 D BackupManagerService: Killing agent host process
# 02-01 20:20:27.381  3758 22126 E BackupManagerService: Internal exception during full backup
# 02-01 20:20:27.381  3758 22126 E BackupManagerService: java.lang.IndexOutOfBoundsException
# 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at java.util.zip.DeflaterOutputStream.write(DeflaterOutputStream.java:205)
# 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService.routeSocketDataToOutput(BackupManagerService.java:3801)
# 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService.-wrap13(BackupManagerService.java)
# 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService$FullBackupEngine.backupOnePackage(BackupManagerService.java:4012)
# 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService$PerformAdbBackupTask.run(BackupManagerService.java:4607)
# 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at java.lang.Thread.run(Thread.java:762)
# Corrupt tar archive in this case:
# tar -tf backup.ab.tar > /dev/null
# tar: Unexpected EOF in archive
# tar: Error is not recoverable: exiting now
# echo $?
# 2
#
# There may be adb backups which don't include the apk inside. In that
# particular case, you need to install the apk first on the device, so the
# adb restore restores the data for your app. Installing the apk afterwards won't work.
# There is generated an html file called apk-missing.html so you can open it and
# install all applications from Play Store on any of your devices. For apps
# downloaded outside Play Store is up to you to back up them before erasing
# the device. In any case it's a good idea to always back up apk's since sometimes
# applications are removed from the store. Titanium Backup, Clockworkmod and
# TWRP are great for that.
# 
# Changelog:
# 02 february 2018
# - "Android Backup Splitter" renamed to "android-backup-splitter"
# - Updated JAVA_VER detection to work with both Oracle java and OpenJDK java
# - Updated JAVA_VER to prevent %0D from adding to bash variable
# - Added detection of corrupt tar file before attempting to split it
# 12 october 2015
# - Use Tar Binary Splitter to avoid having to extract the main tar
# - Replace sh with bash to prevent issues
# - Replace app-ab with split-ab because now shared is included
# - Replace app-tar with split-android
# - Bugfix: Add quotation marks sourrounding most $ variables. In case there are spaces to keep it working
#	Probably it's not completely right but should work for standard use
# - Ignore checking for apk in shared
# - Use $apk_cnt, $apk_miss_cnt and $shared_cnt to notify
# - $SCRIPT_DIR set to relative value "." so it works with
#	Cygwin. Using absolute unix path doesn't work with java on
#	Windows, the path has to be converted to dos path first if used.
#	For example 'cygpath.exe -m "${SCRIPT_DIR}"/'
#
###############################################################

##1 Test for needed applications.
command -v tar >/dev/null 2>&1 || { echo "tar is required but is not installed. Aborting." >&2; exit 1; }
command -v mkdir >/dev/null 2>&1 || { echo "mkdir is required but is not installed. Aborting." >&2; exit 1; }
command -v grep >/dev/null 2>&1 || { echo "grep is required but is not installed. Aborting." >&2; exit 1; }
command -v rm >/dev/null 2>&1 || { echo "rm is required but is not installed. Aborting." >&2; exit 1; }
command -v sed >/dev/null 2>&1 || { echo "sed is required but is not installed. Aborting." >&2; exit 1; }

##2 Require java 7 or higher because of SYNC_FLUSH mode for the Deflater
# If you are going to use ab encryption you need also Java Cryptography Extension (JCE)
command -v java >/dev/null 2>&1 || { echo "java is not installed, 1.7 or higher required. Aborting." >&2; exit 1; }
# Should work with both Oracle java and OpenJDK java
# The "tr -d '\r'" command at the end prevents the infamous ": integer expression expected" when comparing
JAVA_VER=$(java -version 2>&1 | sed 's/..* version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q' | tr -d '\r')
#JAVA_VER=$(($JAVA_VER+0))
##SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_DIR="."
if [ "$JAVA_VER" -lt 17 ] ; then
	echo "java 1.7 or higher is required. Aborting."
	exit 1
fi

###############################################################

##3 Test if any argument is given, and if, test for files existence.
# $1 = name with extension of the adb backup file which must be provided
# $2 = in case the backup is encrypted there should go the password
# Backup file, abe and tar-bin-split must exist

if [ -z "$1" ]; then 
	echo "Usage: bash adb-split.sh backup.ab [password if needed]"
	echo "Resulting files go in split-ab folder"
	exit 1
fi
if [ ! -f "$1" ]; then
	echo "File $1 doesn't exist on present dir. Aborting."
	exit 1
fi
if [ ! -f "${SCRIPT_DIR}"/abe.jar ]; then
	echo "abe.jar doesn't exist on present dir. Aborting."
	exit 1
fi
if [ ! -f "${SCRIPT_DIR}"/tar-bin-split.jar ]; then
	echo "tar-bin-split.jar doesn't exist on present dir. Aborting."
	exit 1
fi

	##4 Convert the ab backup to tar archive, and detect conversion fails.
	# It can fail for 3 reasons: JCE is not present when necessary, password is incorrect or backup is corrupt.
	TARFILE="$1".tar
	echo "Extracting ab archive..."
	java -jar "${SCRIPT_DIR}"/abe.jar unpack "$1" "$TARFILE" "$2"
	if [ $? -ne 0 ]; then
		echo "Java failed to extract the ab archive. Aborting."
		exit 1
	fi
	echo "Done"
	
	##5 Check if tar archive is valid before even attempting to process it
	echo "Checking tar integrity..."
	tar -tf "$TARFILE" > /dev/null
	if [ $? -ne 0 ]; then
		echo "* \"$TARFILE\" archive is corrupt."
		echo "* TIP: probably this is caused by a bug in android, which generates an invalid backup or crashes during the process."
		echo "* TIP: Google has been notified several times about buggy backup service, but refuses to fix it."
		echo "* TIP: Run 'adb logcat -s BackupManagerService' on another terminal before and while making the backup to detect the error."
		echo "       Check for E in fifth column"
		exit 1
	fi
	echo "Done"
	
	##6 Split tarfile by app and shared using Tar Binary Splitter
	echo "Splitting tar..."
	java -jar "${SCRIPT_DIR}"/tar-bin-split.jar -split-android "$TARFILE"
		if [ $? -ne 0 ]; then
		echo "Tar Binary Splitter failed. Aborting."
		exit 1
	fi
	echo "Done"
	if [ ! -d "split-ab" ]; then
		mkdir split-ab
	fi
	
	##7 Convert tar to adb and encrypt with password (if any)
	echo "Creating individual adb backups..."
	for i in split-android/* ; do 
		java -jar "${SCRIPT_DIR}"/abe.jar pack "$i" split-ab/`basename "$i" .tar`.ab "$2" > /dev/null
		if [ $? -ne 0 ]; then
			echo "java failed to compress at `basename "$i"`. Aborting."
			exit 1
		fi
	done
	echo "Done"
	##8 Generate list of missing apk's inside tars. Count also shared if present.
	shared_cnt=0
	apk_cnt=0
	apk_miss_cnt=0
	echo "Checking for apk existence..."
	echo "<HTML><BODY>" > apk-missing.html
	for i in split-android/* ; do
		if [ "$(basename "$i")" == "shared.tar" ] ; then
			let shared_cnt+=1
		else
			let apk_cnt+=1
			tar -tf "$i" | grep apk$ > /dev/null
			if [ $? -ne 0 ] ; then
				# echo "Warning: apk not found in `basename "$i"`"
				echo "<A HREF=\"https://play.google.com/store/apps/details?id=`basename "$i" .tar`\">" >> apk-missing.html
				echo "`basename "$i" .tar`</A><BR>" >> apk-missing.html
				let apk_miss_cnt+=1
			fi
		fi
	done
	echo "</BODY></HTML>" >> apk-missing.html
	grep google apk-missing.html > /dev/null && echo "There are $apk_miss_cnt apk missing. Generating apk-missing.html"
	
	##9 Check for apk existence, and if not warn and add to html file
	echo "Cleaning temporal files..."
	grep google apk-missing.html > /dev/null || rm apk-missing.html
	rm "$TARFILE"
	rm -rf split-android
	echo "Done"
echo "Backup splitting complete: $apk_cnt Apps processed."
if [ "$shared_cnt" -gt 0 ] ; then
	echo "$shared_cnt shared processed."
fi
