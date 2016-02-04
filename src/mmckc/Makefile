#
# makefile for mmckc MinGW and POSIX
#
# if you'd like to make DEBUG executable,
#  make DEBUG=1
#

# DEBUG = 1

CFLAGS = 

ifdef WIN32
CFLAGS += -finput-charset=utf-8 -fexec-charset=cp932
PFX=i586-mingw32-
EXESFX = .exe
OBJDIR = objs_w32

else

PFX=
OBJDIR = objs
CFLAGS += -DUNIX
EXESFX = 

endif

CC = $(PFX)gcc

MAKODIR = $(OBJDIR)/
CMDODIR = $(OBJDIR)/

MKDIR = mkdir -p
CP = cp
RM = rm -rf
INSTDIR = ../../bin


ifdef DEBUG 

 CFLAGS += -g
 CFLAGS += -Wall# -mno-cygwin

else

 CFLAGS += -O2
 EXT_TARGET = strip

endif

CDEFS = 
LDFLAGS= # -mno-cygwin

OBJS = datamake.o file.o mckc.o strings.o

.PHONY: all clean strip objdir install
PRGNAME = mmckc

TARGET_E = $(PRGNAME)$(EXESFX)
TARGET = $(PRGNAME)_j$(EXESFX)

all: objdir $(TARGET_E) $(TARGET) $(EXT_TARGET)

objdir : 
	$(MKDIR) $(CMDODIR)

$(TARGET_E): $(addprefix $(MAKODIR),$(OBJS) version_e.o) 
	$(CC) $(LDFLAGS) -o $@ $^

$(TARGET): $(addprefix $(MAKODIR),$(OBJS) version.o)
	$(CC) $(LDFLAGS) -o $@ $^

strip : $(TARGET_E) $(TARGET)
	$(PFX)strip $^

$(MAKODIR)version_e.o: version.c
	$(CC) $(CFLAGS) $(CDEFS) -DENGLISH -o $@ -c $^

$(MAKODIR)%.o : %.c
	$(CC) $(CFLAGS) $(CDEFS) -c $< -o $@

$(MAKODIR)mckc.o: mckc.h
$(MAKODIR)datamake.o: mckc.h

install:
	$(CP) $(TARGET_E) $(INSTDIR)
	$(CP) $(TARGET) $(INSTDIR)

clean:
	$(RM) $(OBJDIR)
	$(RM) $(TARGET_E) $(TARGET)

