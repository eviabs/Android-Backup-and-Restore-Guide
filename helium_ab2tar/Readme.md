## *helium_ab2tar* - Convert ab backup to tar archive and vice versa ##


Instructions are taken from here: https://forum.xda-developers.com/showpost.php?p=75862940&postcount=7

> Hi, the "helium_ab2tar" finally helped me. Good work!
> I was running Win7 and didn't have any C compiler installed, so here is what I found:
> • from the link above, extract helium_ab2tar-master.zip to a new directory
> • from http://gnuwin32.sourceforge.net/packages/make.htm download Binaries and Dependencies and extract files make.exe, libintl3.dll, libiconv2.dll to your helium_ab2tar-master directory
> • from https://bellard.org/tcc/ download a recent TinyCC build and extract the whole zip into your helium_ab2tar-master directory
> • edit the makefile and change "CC=gcc" to "CC=tcc\tcc.exe"
> • change "-o ab2tar_cut" to "-o ab2tar_cut.exe", "-o ab2tar_corr" to "-o ab2tar_corr.exe", "-o tar2ab_cut" to "-o tar2ab_cut.exe", "-o tar2ab_corr" to "-o tar2ab_corr.exe"
> • finally run make.exe
> 
> How to use: 
> ab2tar_cut [.ab file] [temporary file] 
> ab2tar_corr [temporary file] [.tar file]

The folder [extracted files](https://github.com/eviabs/Android-Backup-and-Restore-Guide/tree/master/helium_ab2tar/extracted%20files) contains the files I had already compiled. 
It Should work on Windows 8 and above, 64bit.
