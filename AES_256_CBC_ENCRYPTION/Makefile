#
# Makefile for QUBIP AES DEMO
#
#  Created on: 30/07/2024
#      Author: apurba@imse-cnm.csic.es
#
############################################################################################

#	Uncomment the used board, operation environment & AXI BUS WIDTH

BOARD    = PYNQZ2
#BOARD   = G2RISCV 

OPENV    = PYNQ
#OPENV   = RISCV

BUSW	 = AXI32
#BUSW	 = AXI64

############################################################################################

CC       = gcc
CP 		 = g++
CFLAGS   = -Wall
LDFLAGS  = -lm

rm       = rm -f
 
PYNQ_DIR = /home/xilinx/pynq

ifneq ("$(wildcard $(PYNQ_DIR))", "")
  LDFLAGS +=  -lpynq -lcma -lpthread
endif

BITDIR = bit
SRCDIR = src
BINDIR = bin
OUTDIR = out

PROGS = aes_test
		 
BINS  = $(patsubst %,$(BINDIR)/%,$(PROGS))


			   
AES_SOURCES_T = $(SRCDIR)/aes/mmio.c $(SRCDIR)/aes/aes_axi.c $(SRCDIR)/aes/aes_test.c 
AES_HEADERS   = $(SRCDIR)/aes/mmio.h $(SRCDIR)/aes/aes_axi.h



REVISION = 1.0_Z2
DIST = RoT_demo_$(REVISION)


.PHONEY: aes_test\
         clean outclean dist distclean

all: $(BINS)
	


bin/aes_test: $(AES_HEADERS) $(AES_SOURCES_T)
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -o $@ $(AES_SOURCES_T) -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)
	


dist:
	rm -rf $(DIST)
	mkdir $(DIST)
	mkdir $(DIST)/$(BITDIR)
	mkdir $(DIST)/$(BINDIR)
	mkdir $(DIST)/$(SRCDIR)
	mkdir $(DIST)/$(SRCDIR)/aes
	mkdir $(DIST)/$(OUTDIR)
	mkdir $(DIST)/$(OUTDIR)/aes
	
	cp Makefile README.md Changelog.md $(DIST)
	
	cp $(BITDIR)/SPIRS_RoT.bit $(DIST)/$(BITDIR)
	cp $(SRCDIR)/aes/*.c  $(SRCDIR)/aes/*.h $(DIST)/$(SRCDIR)/aes
	cp -r $(SRCDIR)/aes/data $(DIST)/$(SRCDIR)/aes
	


	tar cf $(DIST).tar.xz $(DIST) --lzma

clean:
	$(rm) $(BINS)

outclean:
	$(rm) $(OUTDIR)/aes/*.txt 
	
distclean: clean outclean
	rm -rf $(DIST)
	rm -f $(DIST).tar.xz
