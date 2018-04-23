#!/bin/bash
###############################################################
#
# Name: no-adb-backup-app-lister
# Version:  1.2
# Date:     2017/10/14 
# Author:   dragomerlin at sourceforge
# License:  GPL v3
# URL: https://sourceforge.net/projects/no-adb-backup-app-lister/
#
###############################################################
#
# Description:
#
#	This program is a bash script that generates three lists containing
#	listings of apps installed on a given android device, which must
#	be connected to the computer using adb (android debugging bridge).
#
#	One of the list is a file called "ALL_PACKAGES.TXT", which is a list of
#	all the android packages which are present on the device as reported by the device,
#	including both system apps and those installed by the user.
#
#	The other list is mirrored in two files, "NO_ADB_BACKUP_PACKAGES.TXT" and
#	"NO_ADB_BACKUP_PACKAGES.HTML". Both of them contain the list of all packages
#	that don't allow to be backed up by 'adb backup'. One of them is plain text
#	and the other is in html format but the contents are the same.
#	The HTML file may contain only the names of the packages, or can include also
#	the icon of the application, its version and the displayed name or 'label',
#	depending on the user choice when running the script. The user is asked for yes/no.
#	The displayed name or 'label' is the name shown to you, the name they are known for publicly.
#	That is, the name displayed below its icon on the launcher or application drawer.
#   Note that some devices, like the Samsung Galaxy S7 SM-G930F with android 7.0, for example,
#   don't allow to access some files inside /data, so it will not be possible to retrieve
#   the apk and therefore the icons and other information.
#   The error received is "failed to copy '/data/app/com.sygic.aura-2/base.apk' to 'CURRENT_APK.APK': open failed: Permission denied"
#   which may be displayed in a different language if your system is not in english.
#   In any case, it will be detected anyway if the app can be backed up or not, so it's not a big deal.

#   The third list is stored in "OBSCURE_PACKAGES.TXT", which are those packages where 'adb shell dumpsys package'
#   is not able to get proper information about it. What I do is to check for the sentence
#   "Unable to find package: $CURRENT_PACKAGE_NAME", and I take for granted that it will be in english.
#   Don't know if you have the operating system /smartphone /adb in another language if it will still work.
#   This issue only happened to me on Windows with Cygwin, while running the same script on GNU bash on Ubuntu
#   it fetches perfectly the dumpsys information, so a warning is displayed at the begginning if you are running Cygwin.
#   The issue may be caused by weird versions of adb or aapt.
#
# Purpose:
#	This application (no-adb-backup-app-lister) exists to inform you which apps
#	will be missing on your .ab file once you perform an adb backup. Ideally, android should
#	inform you, at the moment of making a backup, that certain files won't be backed
#	up, so you know beforehand that you will lose that information if you do a
#	factory reset. Unfortunately, android just does it silently, and only after you restore your
#	adb backup, you will notice that there are apps and further information missing.
#	This issue has been reported to Google several times for more than 10 years, and still they
#	didn't fix it.
#
# How it works:
#	Using adb, this program runs several commands on the remote device, more or less of them
#	depending if the user want to fetch also icons, version and label or not.
#	The basic steps:
#   * Check if the script is running on Cygwin and warn the user about it.
#	* Check that the required command line tools are present.
#	* Ask user if it wants basic information (apps' names) or extended too (icons, labels and versions).
#	* Get from the phone the list of all apps (adb shell pm list packages -f).
#	* For each app, get the list of flags inside 'Hidden system packages' and 'Packages'
#	  (adb shell dumpsys package).
#	* If the flag "ALLOW_BACKUP" is present on all flags for the same app, determine that is allows
#	  its data to be saved through adb backup.
#	* If the user agreed, get the apk for all apps inside the device, and extract the icon of the
#	  app, the version, the label and the icon, and save it properly to the HTML file. It will
#	  always include the link to the Google Play Store, in case you want to go there. Note that not
#	  every app can be downloaded from the play Store, specially apps that are system-only one or
#	  those that don't meet the Terms of Use to be published there. In that case, you have to
#	  remember where you got that app from or if is just included with the ROM itself.
#
# What is required:
#	The script is designed to work with GNU Bash, and works successfully with Cygwin under Windows 10.
#	It should work also flawlessly under GNU/Linux provided that you are running the script with GNU Bash.
#	Some users complain about macOS (formerly Mac OSX) because its shell (Terminal) may not be entirely
#	compliant with GNU Bash, so know this beforehand and install the GNU version to test.
#
#	- On the android side, it is required to have "Developer options" enabled and allow "ADB Debugging Bridge",
#	  and also authorize the device after you connect it for the first time.
#	  Also, the script takes for granted that only one adb device is connected at the same time.
#
#	- On the computer side, GNU Shell or compatible is required, among other common shell utilities.
#	  These utilities are: bash, echo, rm, mkdir, read, grep, sed, awk, tail, unzip, adb, aapt.
#	  "adb" and "aapt" are android tools which must be downloaded separately and add them to PATH so they
#	  can be run as commands from anywhere in shell.
#	-- On most GNU/Linux distributions, GNU Bash is included by default, with additional software available
#	from its respective repositories.
#	-- macOS (OSX) uses a BSD version of the tools, but GNU Bash can be installed with Homebrew (http://brew.sh):
#	   https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/
#	-- On Windows there's Cygwin (https://cygwin.com/) which works very well despite some minor bug here and there.
#	   It has a software manager to install additional software.
#
# Additional hacking:
#	The capability of some app to be backed up by adb backup is specified inside the AndroidManifest.xml file which
#	is inside each apk. There may exist the flag "android:allowBackup" set to 'true' or 'false', which strictly defines
#	whether the app can be backed up or not.
#	If the flag is not specified, it's up to android to decide if apps without that flag are to be backed up or not.
#	Depending on the android version the default behavior is different.
#
#	You can decompile the apk, edit the 'AndroidManifest.xml' and then recompile and install, to force the application
#	to work with adb backup, but you will have to patch and update the app each time a new version is released because
#	the signing key will be different. There's a xda thread for further information:
#	- [GUIDE] How to enable adb backup for any app changing android:allowBackup:
#		http://forum.xda-developers.com/android/software-hacking/guide-how-to-enable-adb-backup-app-t3495117
#
###############################################################

# 1.1: Check for Cygwin, and warn about it
if uname | grep -i -q 'Cygwin'
then
    echo "You are running Cygwin, which may cause to get obscure packages,"
    echo "  it is recommended that you use Linux with GNU bash instead."
    echo ""
    read -rsp $'Press enter key to continue or 'CTRL+C' to exit...'
    echo -e "\n"
fi

# 1.2: Test for needed applications
command -v rm >/dev/null 2>&1 || { echo "rm is required but is not installed. Aborting." >&2; exit 1; }
command -v mkdir >/dev/null 2>&1 || { echo "mkdir is required but is not installed. Aborting." >&2; exit 1; }
command -v read >/dev/null 2>&1 || { echo "read is required but is not installed. Aborting." >&2; exit 1; }
command -v grep >/dev/null 2>&1 || { echo "grep is required but is not installed. Aborting." >&2; exit 1; }
command -v sed >/dev/null 2>&1 || { echo "sed is required but is not installed. Aborting." >&2; exit 1; }
command -v awk >/dev/null 2>&1 || { echo "awk is required but is not installed. Aborting." >&2; exit 1; }
command -v tail >/dev/null 2>&1 || { echo "tail is required but is not installed. Aborting." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but is not installed. Aborting." >&2; exit 1; }
command -v adb >/dev/null 2>&1 || { echo "adb is not present on PATH. Aborting." >&2; exit 1; }
command -v aapt >/dev/null 2>&1 || { echo "aapt is not present on PATH. Aborting." >&2; exit 1; }

# 2: Remove previous files and clean 'icons/' folder
if [ -f NO_ADB_BACKUP_PACKAGES.TXT ]
then
	rm NO_ADB_BACKUP_PACKAGES.TXT
fi
if [ -f ALL_PACKAGES.TXT ]
then
	rm ALL_PACKAGES.TXT
fi
if [ -f OBSCURE_PACKAGES.TXT ]
then
	rm OBSCURE_PACKAGES.TXT
fi
if [ -f NO_ADB_BACKUP_PACKAGES.HTML ]
then
	rm NO_ADB_BACKUP_PACKAGES.HTML
fi
if [ -d "icons" ]; then 
	if [ -L "icons" ]; then
		# It is a symlink!
		# Symbolic link specific commands go here.
		rm "icons/"
	else
		# It's a directory!
		# Directory command goes here.
		rm -r "icons/"
	fi
	mkdir "icons/"
fi

# 3: Add to HTML file phone model, current computer date and title
echo "device model: $(adb shell getprop ro.product.model)<BR>" >> NO_ADB_BACKUP_PACKAGES.HTML
echo "adb device ID: $(adb devices | grep -v "List of devices" | awk -F"['\t']" '{print $1}')<BR>" >> NO_ADB_BACKUP_PACKAGES.HTML
echo "Computer date: $(date -R)<BR>" >> NO_ADB_BACKUP_PACKAGES.HTML
echo "<BR>LIST OF PACKAGES THAT DON'T ALLOW ADB BACKUP<HR>" >> NO_ADB_BACKUP_PACKAGES.HTML

# Global variables
GLOBAL_PACKAGE_IS_OBSCURE="false"

# 4: User decides wheter to get apps' labels and icons or not.
#	It may take much longer (18 minutes versus 6 minutes on my device)
GLOBAL_READ_LABEL_ICON="false"
echo "Do you want to fetch also the apps' labels and icons?"
echo "Warning, some devices may not allow to read /data/app/ so this may not work"
echo -n -e "It takes considerably longer (y/\033[4mn\033[0m) [Hit enter to use defaults] "
read answer
if echo "$answer" | grep -iq "^y" ;then
    GLOBAL_READ_LABEL_ICON="true"
	echo "You've chosen to read packages' labels."
else
    echo "You've chosen not to read packages' labels."
fi


# 5: get the list of all android packages and count them
echo "Getting list of all packages..."
adb shell pm list packages -f | grep -v '^$' > ALL_PACKAGES.TXT
if [ $? -eq 0 ]
then
    echo "done."
else
    echo "failed."
	exit 1
fi
# Get the total number of packages:
echo "Getting number of total packages..."
NUMBEROFPACKAGES="$(wc -l < ALL_PACKAGES.TXT)"
if [ $? -eq 0 ]
then
    echo "$NUMBEROFPACKAGES packages found."
	echo "done."
else
    echo "failed."
	exit 1
fi


# 6: Each package information goes in a line. Get package's apk path and package name:
echo "Getting list of packages that don't allow adb backup:"
for i in $(seq 1 $NUMBEROFPACKAGES)
do
	CURRENT_PACKAGE_ALLOWS_BACKUPS="true"
	CURRENT_PACKAGE_HAS_HIDDEN_PACKAGES="false"
	CURRENT_LINE=`sed -n "$i"p ALL_PACKAGES.TXT`
	CURRENT_PACKAGE_APK_PATH="$(echo "$CURRENT_LINE" | awk -v FS="(:|=)" '{print $2}')"
	#CURRENT_PACKAGE_APK_PATH=`echo "$CURRENT_LINE" | awk -v FS="(:|=)" '{print $2}'`
	CURRENT_PACKAGE_NAME="$(echo "$CURRENT_LINE" | awk -v FS="(:|=)" '{print $3}')"
	DUMPSYS_OF_CURRENT_PACKAGE="$(adb shell dumpsys package "$CURRENT_PACKAGE_NAME")"
	adb shell dumpsys package "$CURRENT_PACKAGE_NAME" | grep -v '^$' > CURRENT_PACKAGE_DUMPSYS.TXT
	#echo "$CURRENT_PACKAGE_APK_PATH -> $CURRENT_PACKAGE_NAME"
	#echo "$CURRENT_LINE" 
#	CURRENT_PACKAGE_NAME=`sed -n "$i"p all_packages.txt`
#	CURRENT_PACKAGE_NUMBER_OF_APKS=`adb shell pm list packages -f "$CURRENT_PACKAGE_NAME" | grep -oh ".apk=" | wc -l`
#	if [ "$CURRENT_PACKAGE_NUMBER_OF_APKS" -gt "1" ]
#		then
#			echo "$CURRENT_PACKAGE_NAME"
#	fi
#	
	# 6.0: Detect obscure packages: those that appear listed on "adb shell pm list packages -f" but
	# no information is provided when performing "adb shell dumpsys package $CURRENT_PACKAGE_NAME" onm the package.
	# Warning, the message may not be in english!
	if grep -q "Unable to find package: $CURRENT_PACKAGE_NAME" CURRENT_PACKAGE_DUMPSYS.TXT
	then
		GLOBAL_PACKAGE_IS_OBSCURE="true"
		echo "$CURRENT_LINE" >> OBSCURE_PACKAGES.TXT
	else
		# 6.1: Detect if the current app has hidden system packages:
		if grep -q '^Hidden system packages:' CURRENT_PACKAGE_DUMPSYS.TXT ; then
			#echo "$CURRENT_PACKAGE_NAME -> has hidden packages."
			CURRENT_PACKAGE_HAS_HIDDEN_PACKAGES="true"
			CURRENT_PACKAGE_STARTING_LINE_OF_HIDDEN_PACKAGES="$(grep -n -m 1 "^Hidden system packages:" CURRENT_PACKAGE_DUMPSYS.TXT | awk -v FS="(:)" '{print $1}')"
#		CURRENT_PACKAGE_LINE_OF_HIDDEN_PACKAGES_FLAGS="$(sed -n '"$CURRENT_PACKAGE_STARTING_LINE_OF_HIDDEN_PACKAGES",$p' CURRENT_PACKAGE_DUMPSYS.TXT | grep -m 1 ' *flags=\[')"
			CURRENT_PACKAGE_LINE_OF_HIDDEN_PACKAGES_FLAGS="$(tail -n +"$CURRENT_PACKAGE_STARTING_LINE_OF_HIDDEN_PACKAGES" CURRENT_PACKAGE_DUMPSYS.TXT | grep -m 1 ' *flags=\[')"
			# The flags of hidden packages must include "ALLOW_BACKUP" to allow backup when hidden packages are present:
			if `echo "$CURRENT_PACKAGE_LINE_OF_HIDDEN_PACKAGES_FLAGS" | grep -q 'ALLOW_BACKUP'`
			then
				CURRENT_PACKAGE_ALLOWS_BACKUPS="true"
			else
				CURRENT_PACKAGE_ALLOWS_BACKUPS="false"
			fi
		fi
		# 6.2 Detect (if applicable) whether main packages allow adb backup or not:
		# Do this only if Hidden system packages don't exist or if they exist they must allow backup:
		# Now search for the first occurrence of "flags="
		if [ "$CURRENT_PACKAGE_ALLOWS_BACKUPS" = "true" ]
		then
			CURRENT_PACKAGE_MAIN_PACKAGES_STARTING_LINE="$(grep -n -m 1 "^Packages:" CURRENT_PACKAGE_DUMPSYS.TXT | awk -v FS="(:)" '{print $1}')"
			CURRENT_PACKAGE_MAIN_PACKAGES_FLAGS_LINE="$(tail -n +"$CURRENT_PACKAGE_MAIN_PACKAGES_STARTING_LINE" CURRENT_PACKAGE_DUMPSYS.TXT | grep -m 1 ' *flags=\[')"
			# The flags of main packages must include "ALLOW_BACKUP" to allow backup:
			if `echo "$CURRENT_PACKAGE_MAIN_PACKAGES_FLAGS_LINE" | grep -q 'ALLOW_BACKUP'`
			then
				CURRENT_PACKAGE_ALLOWS_BACKUPS="true"
			else
				CURRENT_PACKAGE_ALLOWS_BACKUPS="false"
			fi
		fi
		# 6.3 Show information about each package:
		if [ "$CURRENT_PACKAGE_ALLOWS_BACKUPS" = "true" ]
		then
			:
			#echo "$CURRENT_PACKAGE_NAME has the string ALLOW_BACKUP"
		else
	
			if [ "$GLOBAL_READ_LABEL_ICON" = "true" ]
			then
				#echo "$CURRENT_PACKAGE_NAME doesn't allow adb backups"
				if [ -f CURRENT_APK.APK ]
				then
					rm CURRENT_APK.APK 
				fi
				# adb shell pm path "$CURRENT_PACKAGE_NAME"
				adb pull "$CURRENT_PACKAGE_APK_PATH" CURRENT_APK.APK > /dev/null 2>/dev/null
				
				
				# Check if the apk was received, example: failed to copy '/data/app/com.sygic.aura-2/base.apk' to 'CURRENT_APK.APK': open failed: Permission denied
				# Redirect errors to /dev/null to ignore several aapt errors (or package misconfiguration)
				if [ ! -f CURRENT_APK.APK ]
				then
                    echo "* $CURRENT_PACKAGE_APK_PATH could not be retrieved, skipping icon"
				else
                    CURRENT_PACKAGE_LABEL_LINE="$(aapt dump badging CURRENT_APK.APK 2>/dev/null | grep 'application: label=')"
                    # Warning some labels are empty (''). Other times they are in random language (should be in english by default).
                    #WORKSTOO# CURRENT_PACKAGE_LABEL="$(echo $CURRENT_PACKAGE_LABEL_LINE | awk -F"[']" 'NF>2{print $2}')"
                    CURRENT_PACKAGE_LABEL="$(echo $CURRENT_PACKAGE_LABEL_LINE | sed 's/^.*label=//' | awk -F"[']" '{print $2}')"
                    # There can be two versions, one for the updated package and other for the hidden one. The newest is displayed first.
                    #WORKSTOO# CURRENT_PACKAGE_VERSION="$(adb shell dumpsys package $CURRENT_PACKAGE_NAME | sed -n '/^Packages:/,$p' | grep -m 1 'versionName=' | cut -d "=" -f2)"
                    CURRENT_PACKAGE_VERSION="$(aapt d --values badging CURRENT_APK.APK 2>/dev/null | grep 'versionName=' | sed 's/^.*versionName=//' | awk -F"[']" '{print $2}')"
                    CURRENT_PACKAGE_ICON_RELATIVE_PATH="$(aapt d --values badging CURRENT_APK.APK 2>/dev/null | sed -n "/^application: /s/.*icon='\([^']*\).*/\1/p")"
                    CURRENT_PACKAGE_ICON_EXTENSION="$(echo $CURRENT_PACKAGE_ICON_RELATIVE_PATH | awk -F . '{if (NF>1) {print $NF}}')"
                    #WORKSTOO# unzip -p CURRENT_APK.APK "$CURRENT_PACKAGE_ICON_RELATIVE_PATH" > "icons/$CURRENT_PACKAGE_NAME.png"
                    CURRENT_PACKAGE_ICON_NAME_PLUS_EXTENSION="$CURRENT_PACKAGE_NAME.$CURRENT_PACKAGE_ICON_EXTENSION"
                    #echo "Current package label is: $CURRENT_PACKAGE_LABEL_LINE"
                    echo "$CURRENT_PACKAGE_NAME" >> NO_ADB_BACKUP_PACKAGES.TXT
                    #echo "$CURRENT_PACKAGE_NAME -> $CURRENT_PACKAGE_LABEL -> $CURRENT_PACKAGE_ICON_RELATIVE_PATH"
                    # Add icon to html if exists and avoid xml (android's VectorDrawable which must be decompiled from apk). Convert to lowercase before comparing
                    if [ -z "$CURRENT_PACKAGE_ICON_RELATIVE_PATH" ] || [ "${CURRENT_PACKAGE_ICON_EXTENSION,,}" == "xml" ]
                    then
                        # Don't fetch icon
                        :
                    else
                        # Sometimes the file provided by "application: label=''" does not exist, so we must check before
                        if (unzip -t CURRENT_APK.APK "$CURRENT_PACKAGE_ICON_RELATIVE_PATH" > /dev/null 2>&1)
                        then
                            # Save the icon of the package to the icons/ folder with the name of the package and the proper extension
                            # Add the image to the html code
                            # <img src="pic_mountain.jpg" alt="Mountain View" style="width:304px;height:228px;">
                            unzip -p CURRENT_APK.APK "$CURRENT_PACKAGE_ICON_RELATIVE_PATH" 2>/dev/null > "icons/$CURRENT_PACKAGE_ICON_NAME_PLUS_EXTENSION"
                            echo "<IMG SRC=\"icons/$CURRENT_PACKAGE_ICON_NAME_PLUS_EXTENSION\">&nbsp;" >> NO_ADB_BACKUP_PACKAGES.HTML
                        fi
				
                    fi
                    echo "* $CURRENT_PACKAGE_NAME processed"
				fi
				
				echo "<A HREF=\"https://play.google.com/store/apps/details?id=$CURRENT_PACKAGE_NAME\">" >> NO_ADB_BACKUP_PACKAGES.HTML
				echo "$CURRENT_PACKAGE_NAME</A>&nbsp;-&nbsp;$CURRENT_PACKAGE_LABEL&nbsp;-&nbsp;$CURRENT_PACKAGE_VERSION<BR><HR>" >> NO_ADB_BACKUP_PACKAGES.HTML
			else
				# Just output the package name with the Google Play Store link (avoid pulling apk from device which takes a lot of time)
				echo "$CURRENT_PACKAGE_NAME" >> NO_ADB_BACKUP_PACKAGES.TXT
				echo "* $CURRENT_PACKAGE_NAME"
				echo "<A HREF=\"https://play.google.com/store/apps/details?id=$CURRENT_PACKAGE_NAME\">" >> NO_ADB_BACKUP_PACKAGES.HTML
				echo "$CURRENT_PACKAGE_NAME</A><BR><HR>" >> NO_ADB_BACKUP_PACKAGES.HTML
			fi
		fi
	fi
done
echo "done."


# 7: Cleanup and inform
if [ -f CURRENT_PACKAGE_DUMPSYS.TXT ]
then
	rm CURRENT_PACKAGE_DUMPSYS.TXT
fi
if [ -f CURRENT_APK.APK ]
then
	rm CURRENT_APK.APK
fi
echo "Job finished."
echo "See \"ALL_PACKAGES.TXT\", NO_ADB_BACKUP_PACKAGES.HTML\" and \"OBSCURE_PACKAGES.TXT\" for more details"
