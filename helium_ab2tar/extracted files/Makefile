default: build
.PHONY: clean

CC=tcc\tcc.exe
CFLAGS=

# name of the helium backup file to extract
BACKUP = backup.ab
# name of the folder to extract to
TARGET = helium

build: ab2tar_cut.exe ab2tar_corr.exe tar2ab_corr.exe tar2ab_cut.exe

ab2tar_cut.exe: ab2tar_cut.c
	$(CC) ab2tar_cut.c -o ab2tar_cut.exe $(CFLAGS)
ab2tar_corr.exe: ab2tar_corr.c
	$(CC) ab2tar_corr.c -o ab2tar_corr.exe $(CFLAGS)
tar2ab_corr.exe: tar2ab_corr.c
	$(CC) tar2ab_corr.c -o tar2ab_corr.exe $(CFLAGS)
tar2ab_cut.exe: tar2ab_cut.c
	$(CC) tar2ab_cut.c -o tar2ab_cut.exe $(CFLAGS)

clean:
	rm -f ab2tar_cut.exe ab2tar_corr.exe tar2ab_cut.exe tar2ab_corr.exe

extract: build $(BACKUP)
	./ab2tar_cut.exe $(BACKUP) b.tmp > /dev/null
	./ab2tar_corr.exe b.tmp b.tar > /dev/null
	mkdir -p $(TARGET)/$(BACKUP)
	tar -xf b.tar -C $(TARGET)/$(BACKUP)
	rm -f b.tmp b.tar
	@echo "extracted to folder: \"$(TARGET)/$(BACKUP)\""
