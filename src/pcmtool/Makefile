#
# Makefile
#

CC = gcc
STRIP = strip
SFX = .exe
RM = rm
CP = cp

TARGET = pcmtool$(SFX)
OBJS = pcmtool.o
CFLAGS = -O2

all : $(TARGET)

clean: 
	$(RM) -f $(OBJS)
	$(RM) -f $(TARGET)

install: $(TARGET)
	$(CP) $(TARGET) ../../bin

$(TARGET) : $(OBJS)
	$(CC) -o $@ $^
	$(STRIP) $@

%.o : %.c
	$(CC) -c $(CFLAGS) -o $@ $<

