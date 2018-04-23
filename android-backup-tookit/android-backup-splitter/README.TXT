###############################################################

Name: ADB Backup Splitter (non extraction method)
File: adb-split-no-extraction.sh
Author: dragomerlin
License: GPL v3

 Description:

 This bash script utility reads an adb backup, and for each android app or sdcard (shared) inside,
 creates a single backup of its own into a folder. So basically is useful for
 splitting one big unmanageable file into little ones, so you can store or restore android apps 
 or sdcards individually. Because, as we know, adb restore does not allow for any kind of selection
 at restore time, it just does all at once.
 The resulting ab(s) go into the split-android/. This script works on Cygwin also. Should work on OS X too.
 The goodness of this method is that thanks to the capabilities of
 tar-binary-splitter it splits a tar archive without actually extracting
 the contents to the hard drive and then re-archiving. Thus there's no issue
 even if there are incompatible characters in the filename or path.
 This is the recommended method for splitting an adb backup.

 Creating a backup with -shared flag has known issues (corruption),
 so is not recommended. Use the flag -noshared

 Sometimes, using the flag -nocompress can help when this errors happen on logcat:
 02-01 20:15:26.961  3758 22126 D BackupManagerService: Binding to full backup agent : com.example
 02-01 20:15:26.987  3758 22126 D BackupManagerService: awaiting agent for ApplicationInfo{e6e6d23 com.example}
 02-01 20:15:27.173  3758  5719 D BackupManagerService: agentConnected pkg=com.example agent=android.os.BinderProxy@bca7efe
 02-01 20:15:27.174  3758 22126 I BackupManagerService: got agent android.app.IBackupAgent$Stub$Proxy@e5da65f
 02-01 20:15:27.175  3758 25265 D BackupManagerService: Writing manifest for com.example
 02-01 20:15:27.176  3758 25265 D BackupManagerService: Calling doFullBackup() on com.example
 02-01 20:15:27.176  3758 25265 V BackupManagerService: starting timeout: token=1345547b interval=300000 callback=com.android.server.backup.BackupManagerService$PerformAdbBackupTask@19db723
 02-01 20:20:27.277  3758  5050 V BackupManagerService: TIMEOUT: token=1345547b
 02-01 20:20:27.277  3758  5050 V BackupManagerService:    Invoking timeout on com.android.server.backup.BackupManagerService$PerformAdbBackupTask@19db723
 02-01 20:20:27.277  3758  5050 W BackupManagerService: adb backup timeout of PackageInfo{3b3574a com.example}
 02-01 20:20:27.279  3758  5050 D BackupManagerService: Killing agent host process
 02-01 20:20:27.381  3758 22126 E BackupManagerService: Internal exception during full backup
 02-01 20:20:27.381  3758 22126 E BackupManagerService: java.lang.IndexOutOfBoundsException
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at java.util.zip.DeflaterOutputStream.write(DeflaterOutputStream.java:205)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService.routeSocketDataToOutput(BackupManagerService.java:3801)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService.-wrap13(BackupManagerService.java)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService$FullBackupEngine.backupOnePackage(BackupManagerService.java:4012)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService$PerformAdbBackupTask.run(BackupManagerService.java:4607)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at java.lang.Thread.run(Thread.java:762)
 Corrupt tar archive in this case:
 tar -tf backup.ab.tar > /dev/null
 tar: Unexpected EOF in archive
 tar: Error is not recoverable: exiting now
 echo $?
 2
 
 There may be adb backups which don't include the apk inside. In that
 particular case, you need to install the apk first on the device, so the
 adb restore restores the data for your app. Installing the apk afterwards won't work.
 There is generated an html file called apk-missing.html so you can open it and
 install all applications from Play Store on any of your devices. For apps
 downloaded outside Play Store is up to you to back up them before erasing
 the device. In any case it's a good idea to always back up apk's since sometimes
 applications are removed from the store. Titanium Backup, Clockworkmod and
 TWRP are great for that.
 
 Changelog:
 02 february 2018
 - "Android Backup Splitter" renamed to "android-backup-splitter"
 - Updated JAVA_VER detection to work with both Oracle java and OpenJDK java
 - Updated JAVA_VER to prevent %0D from adding to bash variable
 - Added detection of corrupt tar file before attempting to split it
 12 october 2015
 - Use Tar Binary Splitter to avoid having to extract the main tar
 - Replace sh with bash to prevent issues
 - Replace app-ab with split-ab because now shared is included
 - Replace app-tar with split-android
 - Bugfix: Add quotation marks sourrounding most $ variables. In case there are spaces to keep it working
	Probably it's not completely right but should work for standard use
 - Ignore checking for apk in shared
 - Use $apk_cnt, $apk_miss_cnt and $shared_cnt to notify
 - $SCRIPT_DIR set to relative value "." so it works with
	Cygwin. Using absolute unix path doesn't work with java on
	Windows, the path has to be converted to dos path first if used.
	For example 'cygpath.exe -m "${SCRIPT_DIR}"/'

###############################################################

Name: ADB Backup Splitter (extraction method)
File: adb-split-extraction.sh
Author: dragomerlin
License: GPL v3

 NOTE: it is recommended to use the non extraction method instead

 Description:

 This bash script utility generates an adb backup for each item
 on apps/ folder (not recursively). That equals to generating an adb backup
 for each app.

 shared/0 and shared/1 (sdcards) are ignored, so that means that
 external data and OBB files, although should be backed up, may not
 be restored. For doing so, backup the folder Android of the sdcards.
 
 Creating a backup with -shared flag has known issues (corruption),
 so is not recommended. Use the flag -noshared

 Sometimes, using the flag -nocompress can help when this errors happen on logcat:
 02-01 20:15:26.961  3758 22126 D BackupManagerService: Binding to full backup agent : com.example
 02-01 20:15:26.987  3758 22126 D BackupManagerService: awaiting agent for ApplicationInfo{e6e6d23 com.example}
 02-01 20:15:27.173  3758  5719 D BackupManagerService: agentConnected pkg=com.example agent=android.os.BinderProxy@bca7efe
 02-01 20:15:27.174  3758 22126 I BackupManagerService: got agent android.app.IBackupAgent$Stub$Proxy@e5da65f
 02-01 20:15:27.175  3758 25265 D BackupManagerService: Writing manifest for com.example
 02-01 20:15:27.176  3758 25265 D BackupManagerService: Calling doFullBackup() on com.example
 02-01 20:15:27.176  3758 25265 V BackupManagerService: starting timeout: token=1345547b interval=300000 callback=com.android.server.backup.BackupManagerService$PerformAdbBackupTask@19db723
 02-01 20:20:27.277  3758  5050 V BackupManagerService: TIMEOUT: token=1345547b
 02-01 20:20:27.277  3758  5050 V BackupManagerService:    Invoking timeout on com.android.server.backup.BackupManagerService$PerformAdbBackupTask@19db723
 02-01 20:20:27.277  3758  5050 W BackupManagerService: adb backup timeout of PackageInfo{3b3574a com.example}
 02-01 20:20:27.279  3758  5050 D BackupManagerService: Killing agent host process
 02-01 20:20:27.381  3758 22126 E BackupManagerService: Internal exception during full backup
 02-01 20:20:27.381  3758 22126 E BackupManagerService: java.lang.IndexOutOfBoundsException
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at java.util.zip.DeflaterOutputStream.write(DeflaterOutputStream.java:205)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService.routeSocketDataToOutput(BackupManagerService.java:3801)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService.-wrap13(BackupManagerService.java)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService$FullBackupEngine.backupOnePackage(BackupManagerService.java:4012)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at com.android.server.backup.BackupManagerService$PerformAdbBackupTask.run(BackupManagerService.java:4607)
 02-01 20:20:27.381  3758 22126 E BackupManagerService: 	at java.lang.Thread.run(Thread.java:762)
 Corrupt tar archive in this case:
 tar -tf backup.ab.tar > /dev/null
 tar: Unexpected EOF in archive
 tar: Error is not recoverable: exiting now
 echo $?
 2

 This script works on Cygwin also, and in general where star does.

 There may be adb backups which don't include the apk inside. In that
 particular case, you need to install the apk first on the device so the
 adb restore restores the data for your app. Installing the apk afterwards won't work.
 There is generated an html file called apk-missing.html so you can open it and
 install all applications from Play Store on any of your devices. For apps
 downloaded outside Play Store is up to you to back up them before erasing
 the device. In any case it's a good idea to always back up apk's since sometimes
 applications are removed from the store. Titanium Backup, Clockworkmod and
 TWRP are great for that.
 
 Changelog:
 02 february 2018
 - "Android Backup Splitter" renamed to "android-backup-splitter"
 - Updated JAVA_VER detection to work with both Oracle java and OpenJDK java
 - Updated JAVA_VER to prevent %0D from adding to bash variable
 - Added detection of corrupt tar file before attempting to extract it
 11 october 2015
 - Replace sh with bash to prevent issues
 - Bugfix: Add quotation marks sourrounding most $ variables. In case there are spaces to keep it working
	Probably it's not completely right but should work for standard use
 - adb-split.sh renamed to adb-split_extraction.sh
 18 august 2015
 - Added patch from Andreas Stern: those files with 2 or more backslashes in
	the filename, replace them with a single one when generating app-list/ files.
	This allows star to work on OS X when compressing. I will not work on Cygwin,
	which will use backslash as directory separator instead. star will use exit code
	different from 0 on this case. Check with 'echo $?' to detect this.
	Also use $apk_cnt and $apk_miss_cnt
 - $SCRIPT_DIR set to relative value "." so it works with
	Cygwin. Using absolute unix path doesn't work with java on
	Windows, the path has to be converted to dos path first if used.
	For example 'cygpath.exe -m ${SCRIPT_DIR}/'

