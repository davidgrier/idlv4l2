# Makefile for idlv4l2.so
#
# Shared object library to capture images from a video4linux2 device
#
# Modification history
# 01/11/2011: Written by David G. Grier, New York University
#
TARGET = idlv4l2
PACKAGE = $(TARGET)lib
BINDIR = /usr/local/lib
IDLROOT = /usr/local/exelis/idl
IDLDIR = $(IDLROOT)/bin/bin.linux.x86_64
PRODIR = /usr/local/IDL/idlv4l2

CC = gcc
LD = ld
INSTALL = install

CFLAGS = -O -fPIC
INCLUDES = -I$(IDLROOT)/external/include
LD_FLAGS = -shared
LIBS = -lv4l2

OBJS = $(TARGET).o
HEADERS = $(TARGET).h
SOURCES = $(TARGET).c $(HEADERS)
PROS = dgggrv4l2__define.pro \
 idlv4l2_close.pro \
 idlv4l2_init.pro \
 idlv4l2_open.pro \
 idlv4l2_readframe.pro \
 idlv4l2_startcapture.pro \
 idlv4l2_stopcapture.pro \
 idlv4l2_uninit.pro \
 v4lsnap.pro

all: $(TARGET).so

$(TARGET).so: $(OBJS)
	$(LD) $(LD_FLAGS) -o $(TARGET).so $(OBJS) $(LIBS)	

install: $(TARGET).so
	$(INSTALL) $(TARGET).so $(BINDIR)/$(TARGET).so
	ln -sf $(BINDIR)/$(TARGET).so $(IDLDIR)
	-mkdir $(PRODIR)
	$(INSTALL) -m 644 $(PROS) $(PRODIR)
	
clean:
	-rm core $(OBJS) $(TARGET).so *~ 

package: README Makefile $(SOURCES) 
	-mkdir $(PACKAGE)
	cp README Makefile $(SOURCES) $(PACKAGE)
	tar cvzf $(PACKAGE).tgz $(PACKAGE)
	rm -rf $(PACKAGE)

installpackage: package
	scp $(PACKAGE).tgz dg86@rio.physics.nyu.edu:public_html/uploads

.SUFFIXES: .c .o

.c.o :
	$(CC) $(CFLAGS) $(INCLUDES) -c $*.c
