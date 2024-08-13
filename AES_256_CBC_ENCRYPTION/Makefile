#
# Makefile for SPIRS RoT DEMO
#
#  Created on: 12/02/2023
#      Author: santiago@imse-cnm.csic.es
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
RUNDIR = run
OUTDIR = out

PROGS =  puf_getdata puf_enrollment puf_HDintra puf_reliability puf_test\
         puf_es_validation puf_es_health_check\
         sha2_test sha2_spirs aes_test rsa_test
		 
BINS  = $(patsubst %,$(BINDIR)/%,$(PROGS))

SHA2_SOURCES_T = $(SRCDIR)/sha2/sha256.c $(SRCDIR)/sha2/sha2_hw.c $(SRCDIR)/sha2/function_test.c \
                 $(SRCDIR)/sha2/functions_hw.c $(SRCDIR)/sha2/sha2_test.c
SHA2_SOURCES_S = $(SRCDIR)/sha2/sha256.c $(SRCDIR)/sha2/sha2_hw.c $(SRCDIR)/sha2/function_test.c \
                 $(SRCDIR)/sha2/functions_hw.c $(SRCDIR)/sha2/sha2_spirs.c
SHA2_HEADERS   = $(SRCDIR)/sha2/sha256.h $(SRCDIR)/sha2/sha2_hw.h $(SRCDIR)/sha2/function_test.h \
                 $(SRCDIR)/sha2/functions_hw.h
			   
AES_SOURCES_T = $(SRCDIR)/aes/mmio.c $(SRCDIR)/aes/aes_axi.c $(SRCDIR)/aes/aes_test.c 
#AES_SOURCES_S = $(SRCDIR)/aes/mmio.c $(SRCDIR)/aes/aes_axi.c $(SRCDIR)/aes/aes_spirs.c
AES_HEADERS   = $(SRCDIR)/aes/mmio.h $(SRCDIR)/aes/aes_axi.h

RSA_SOURCES   = $(SRCDIR)/rsa/mmio.c $(SRCDIR)/rsa/rsa_axi.c $(SRCDIR)/rsa/rsa_test.c
RSA_HEADERS   = $(SRCDIR)/rsa/mmio.h $(SRCDIR)/rsa/rsa_axi.h


REVISION = 4.0_Z2
DIST = RoT_demo_$(REVISION)


.PHONEY: all puf_getdata puf_enrollment puf_HDintra puf_reliability puf_test\
         puf_es_validation puf_es_health_check \
         sha2_test sha2_spirs aes_test rsa_test\
		 clean outclean dist distclean

all: $(BINS)
	
bin/puf_getdata: $(SRCDIR)/puf/puf_getdata.c $(SRCDIR)/puf/puf4r3.c $(SRCDIR)/puf/puf4r3.h $(SRCDIR)/puf/testsystem.h 
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -o $@ $^ -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)

bin/puf_enrollment: $(SRCDIR)/puf/puf_enrollment.c $(SRCDIR)/puf/puf4r3.c $(SRCDIR)/puf/puf4r3.h $(SRCDIR)/puf/testsystem.h 
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -o $@ $^ -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)

bin/puf_HDintra: $(SRCDIR)/puf/puf_HDintra.c $(SRCDIR)/puf/puf4r3.c $(SRCDIR)/puf/puf4r3.h $(SRCDIR)/puf/testsystem.h 
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -o $@ $^ -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)

bin/puf_reliability: $(SRCDIR)/puf/puf_reliability.c $(SRCDIR)/puf/puf4r3.c $(SRCDIR)/puf/puf4r3.h $(SRCDIR)/puf/testsystem.h 
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -o $@ $^ -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)

bin/puf_test: $(SRCDIR)/puf/puf_test.c $(SRCDIR)/puf/puf4r3.c $(SRCDIR)/puf/puf4r3.h $(SRCDIR)/puf/testsystem.h 
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -o $@ $^ -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)

bin/puf_es_validation: $(SRCDIR)/puf/puf_es_validation.c $(SRCDIR)/puf/puf4r3.c $(SRCDIR)/puf/puf4r3.h $(SRCDIR)/puf/testsystem.h 
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -o $@ $^ -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)
	
bin/puf_es_health_check: $(SRCDIR)/puf/puf_es_health_check.c  
	@echo CFLAGS=$(CFLAGS) 
	$(CP) $(CFLAGS) -o $@ $^ -I. -D$(BOARD) -D$(OPENV) 
	
bin/sha2_test: $(SHA2_HEADERS) $(SHA2_SOURCES_T)
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -DCRYPTO_NAMESPACE\(s\)=SHA2_\#\#s -o $@ $(SHA2_SOURCES_T) -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)

bin/sha2_spirs: $(SHA2_HEADERS) $(SHA2_SOURCES_S)
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -DCRYPTO_NAMESPACE\(s\)=SHA2_\#\#s -o $@ $(SHA2_SOURCES_S) -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)

bin/aes_test: $(AES_HEADERS) $(AES_SOURCES_T)
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -o $@ $(AES_SOURCES_T) -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)
	
#bin/aes_spirs: $(AES_HEADERS) $(AES_SOURCES_S)
#	@echo CFLAGS=$(CFLAGS) 
#	$(CC) $(CFLAGS) -o $@ $(AES_SOURCES_S) -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)

bin/rsa_test: $(RSA_HEADERS) $(RSA_SOURCES)
	@echo CFLAGS=$(CFLAGS) 
	$(CC) $(CFLAGS) -o $@ $(RSA_SOURCES) -L. $(LDFLAGS) -I. -D$(BOARD) -D$(OPENV) -D$(BUSW)
	
dist:
	rm -rf $(DIST)
	mkdir $(DIST)
	mkdir $(DIST)/$(BITDIR)
	mkdir $(DIST)/$(BINDIR)
	mkdir $(DIST)/$(RUNDIR)
	mkdir $(DIST)/$(RUNDIR)/puf
	mkdir $(DIST)/$(RUNDIR)/sha2
	mkdir $(DIST)/$(RUNDIR)/aes
	mkdir $(DIST)/$(RUNDIR)/rsa
	mkdir $(DIST)/$(SRCDIR)
	mkdir $(DIST)/$(SRCDIR)/puf
	mkdir $(DIST)/$(SRCDIR)/sha2
	mkdir $(DIST)/$(SRCDIR)/aes
	mkdir $(DIST)/$(SRCDIR)/rsa
	mkdir $(DIST)/$(OUTDIR)
	mkdir $(DIST)/$(OUTDIR)/puf
	mkdir $(DIST)/$(OUTDIR)/sha2
	mkdir $(DIST)/$(OUTDIR)/aes
	mkdir $(DIST)/$(OUTDIR)/rsa
	
	cp Makefile README.md Changelog.md $(DIST)
	
	cp $(BITDIR)/SPIRS_RoT.bit $(DIST)/$(BITDIR)
	cp $(SRCDIR)/puf/*.c  $(SRCDIR)/puf/*.h   $(DIST)/$(SRCDIR)/puf
	cp $(SRCDIR)/sha2/*.c $(SRCDIR)/sha2/*.h $(DIST)/$(SRCDIR)/sha2
	cp $(SRCDIR)/sha2/input_data.txt $(DIST)/$(SRCDIR)/sha2
	cp -r $(SRCDIR)/sha2/shab* $(DIST)/$(SRCDIR)/sha2
	cp $(SRCDIR)/aes/*.c  $(SRCDIR)/aes/*.h $(DIST)/$(SRCDIR)/aes
	cp -r $(SRCDIR)/aes/data $(DIST)/$(SRCDIR)/aes
	cp $(SRCDIR)/rsa/*.c  $(SRCDIR)/rsa/*.h $(DIST)/$(SRCDIR)/rsa
	cp -r $(SRCDIR)/rsa/data $(DIST)/$(SRCDIR)/rsa
	
	cp $(RUNDIR)/*.sh $(DIST)/$(RUNDIR)
	cp $(RUNDIR)/puf/*.sh $(DIST)/$(RUNDIR)/puf
	cp $(RUNDIR)/sha2/*.sh $(DIST)/$(RUNDIR)/sha2
	cp $(RUNDIR)/aes/*.sh $(DIST)/$(RUNDIR)/aes
	cp $(RUNDIR)/rsa/*.sh $(DIST)/$(RUNDIR)/rsa

	tar cf $(DIST).tar.xz $(DIST) --lzma

clean:
	$(rm) $(BINS)

outclean:
	$(rm) $(OUTDIR)/puf/*.txt $(OUTDIR)/puf/*.bin $(OUTDIR)/sha2/*.txt $(OUTDIR)/aes/*.txt $(OUTDIR)/rsa/*.txt
	
distclean: clean outclean
	rm -rf $(DIST)
	rm -f $(DIST).tar.xz
