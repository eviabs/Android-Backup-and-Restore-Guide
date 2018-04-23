!/bin/bash
##############################################################

 Name: no-adb-backup-app-lister
 Version:  1.2
 Date:     2017/10/14 
 Author:   dragomerlin at sourceforge
 License:  GPL v3
 URL: https://sourceforge.net/projects/no-adb-backup-app-lister/

##############################################################

 Description:

	This program is a bash script that generates three lists containing
	listings of apps installed on a given android device, which must
	be connected to the computer using adb (android debugging bridge).

	One of the list is a file called "ALL_PACKAGES.TXT", which is a list of
	all the android packages which are present on the device as reported by the device,
	including both system apps and those installed by the user.

	The other list is mirrored in two files, "NO_ADB_BACKUP_PACKAGES.TXT" and
	"NO_ADB_BACKUP_PACKAGES.HTML". Both of them contain the list of all packages
	that don't allow to be backed up by 'adb backup'. One of them is plain text
	and the other is in html format but the contents are the same.
	The HTML file may contain only the names of the packages, or can include also
	the icon of the application, its version and the displayed name or 'label',
	depending on the user choice when running the script. The user is asked for yes/no.
	The displayed name or 'label' is the name shown to you, the name they are known for publicly.
	That is, the name displayed below its icon on the launcher or application drawer.
   Note that some devices, like the Samsung Galaxy S7 SM-G930F with android 7.0, for example,
   don't allow to access some files inside /data, so it will not be possible to retrieve
   the apk and therefore the icons and other information.
   The error received is "failed to copy '/data/app/com.sygic.aura-2/base.apk' to 'CURRENT_APK.APK': open failed: Permission denied"
   which may be displayed in a different language if your system is not in english.
   In any case, it will be detected anyway if the app can be backed up or not, so it's not a big deal.

   The third list is stored in "OBSCURE_PACKAGES.TXT", which are those packages where 'adb shell dumpsys package'
   is not able to get proper information about it. What I do is to check for the sentence
   "Unable to find package: $CURRENT_PACKAGE_NAME", and I take for granted that it will be in english.
   Don't know if you have the operating system /smartphone /adb in another language if it will still work.
   This issue only happened to me on Windows with Cygwin, while running the same script on GNU bash on Ubuntu
   it fetches perfectly the dumpsys information, so a warning is displayed at the begginning if you are running Cygwin.
   The issue may be caused by weird versions of adb or aapt.

 Purpose:
	This application (no-adb-backup-app-lister) exists to inform you which apps
	will be missing on your .ab file once you perform an adb backup. Ideally, android should
	inform you, at the moment of making a backup, that certain files won't be backed
	up, so you know beforehand that you will lose that information if you do a
	factory reset. Unfortunately, android just does it silently, and only after you restore your
	adb backup, you will notice that there are apps and further information missing.
	This issue has been reported to Google several times for more than 10 years, and still they
	didn't fix it.

 How it works:
	Using adb, this program runs several commands on the remote device, more or less of them
	depending if the user want to fetch also icons, version and label or not.
	The basic steps:
   * Check if the script is running on Cygwin and warn the user about it.
	* Check that the required command line tools are present.
	* Ask user if it wants basic information (apps' names) or extended too (icons, labels and versions).
	* Get from the phone the list of all apps (adb shell pm list packages -f).
	* For each app, get the list of flags inside 'Hidden system packages' and 'Packages'
	  (adb shell dumpsys package).
	* If the flag "ALLOW_BACKUP" is present on all flags for the same app, determine that is allows
	  its data to be saved through adb backup.
	* If the user agreed, get the apk for all apps inside the device, and extract the icon of the
	  app, the version, the label and the icon, and save it properly to the HTML file. It will
	  always include the link to the Google Play Store, in case you want to go there. Note that not
	  every app can be downloaded from the play Store, specially apps that are system-only one or
	  those that don't meet the Terms of Use to be published there. In that case, you have to
	  remember where you got that app from or if is just included with the ROM itself.

 What is required:
	The script is designed to work with GNU Bash, and works successfully with Cygwin under Windows 10.
	It should work also flawlessly under GNU/Linux provided that you are running the script with GNU Bash.
	Some users complain about macOS (formerly Mac OSX) because its shell (Terminal) may not be entirely
	compliant with GNU Bash, so know this beforehand and install the GNU version to test.

	- On the android side, it is required to have "Developer options" enabled and allow "ADB Debugging Bridge",
	  and also authorize the device after you connect it for the first time.
	  Also, the script takes for granted that only one adb device is connected at the same time.

	- On the computer side, GNU Shell or compatible is required, among other common shell utilities.
	  These utilities are: bash, echo, rm, mkdir, read, grep, sed, awk, tail, unzip, adb, aapt.
	  "adb" and "aapt" are android tools which must be downloaded separately and add them to PATH so they
	  can be run as commands from anywhere in shell.
	-- On most GNU/Linux distributions, GNU Bash is included by default, with additional software available
	from its respective repositories.
	-- macOS (OSX) uses a BSD version of the tools, but GNU Bash can be installed with Homebrew (http://brew.sh):
	   https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/
	-- On Windows there's Cygwin (https://cygwin.com/) which works very well despite some minor bug here and there.
	   It has a software manager to install additional software.

 Additional hacking:
	The capability of some app to be backed up by adb backup is specified inside the AndroidManifest.xml file which
	is inside each apk. There may exist the flag "android:allowBackup" set to 'true' or 'false', which strictly defines
	whether the app can be backed up or not.
	If the flag is not specified, it's up to android to decide if apps without that flag are to be backed up or not.
	Depending on the android version the default behavior is different.

	You can decompile the apk, edit the 'AndroidManifest.xml' and then recompile and install, to force the application
	to work with adb backup, but you will have to patch and update the app each time a new version is released because
	the signing key will be different. There's a xda thread for further information:
	- [GUIDE] How to enable adb backup for any app changing android:allowBackup:
		http://forum.xda-developers.com/android/software-hacking/guide-how-to-enable-adb-backup-app-t3495117
