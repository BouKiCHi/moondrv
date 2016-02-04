
DATE = $(shell date +"%y%m%d")
ZIPNAME = moondrv$(DATE).zip

all: help

help:
	@echo "make <compiler|zip|clean>"

compiler:
	cd src/mmckc/ ; make WIN32=1 clean all install
	cd src/mmckc/ ; make WIN32=1 clean

clean:
	rm -f $(ZIPNAME)

zip:
	zip -r $(ZIPNAME) . -x '.git*' .DS_Store 
	
	