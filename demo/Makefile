# COMPILER
#CC=/usr/bin/cc -O3 -g
CC=/usr/bin/cc

# BOARD
BOARD_ZCU  = ZCU104
BOARD_PYNQ = PYNQZ2

# OPENSSL DIRECTORY
OPENSSL_DIR = /opt/openssl/

# COMPILER FLAGS
LDFLAGS_DEMO = -lpthread -lm -lpynq -lcma
LDFLAGS_DEMO_SPEED = -lpthread -lm -lpynq -lcma -lcryptoapi
LDFLAGS_DEMO_BUILD = -lpthread -lm -lpynq -lcma -L../se-qubip/build/ -lsequbip 
LDFLAGS_DEMO_SPEED_BUILD = -lpthread -lm -lpynq -lcma -lcryptoapi -L../se-qubip/build/ -lsequbip 
LDFLAGS_LIB_OPENSSL = -lpthread -lm -I$(OPENSSL_DIR)include $(OPENSSL_DIR)lib/libcrypto.so.3 -DOPENSSL
CFLAGS_DEMO =

# SOURCE DIRECTORY
SRCDIR = ../se-qubip/src/
SRCDIR_DEMO = src/

# SHA3
LIB_SHA3_HW_SOURCES = $(SRCDIR)sha3/sha3_shake_hw.c
LIB_SHA3_HW_HEADERS = $(SRCDIR)sha3/sha3_shake_hw.h
# SHA2
LIB_SHA2_HW_SOURCES = $(SRCDIR)sha2/sha2_hw.c
LIB_SHA2_HW_HEADERS = $(SRCDIR)sha2/sha2_hw.h
# EDDSA
LIB_EDDSA_HW_SOURCES = $(SRCDIR)eddsa/eddsa_hw.c 
LIB_EDDSA_HW_HEADERS = $(SRCDIR)eddsa/eddsa_hw.h 
# X25519
LIB_X25519_HW_SOURCES = $(SRCDIR)x25519/x25519_hw.c 
LIB_X25519_HW_HEADERS = $(SRCDIR)x25519/x25519_hw.h 
# TRNG
LIB_TRNG_HW_SOURCES = $(SRCDIR)trng/trng_hw.c 
LIB_TRNG_HW_HEADERS = $(SRCDIR)trng/trng_hw.h 
# MLKEM
LIB_MLKEM_HW_SOURCES = $(SRCDIR)mlkem/mlkem_hw.c 
LIB_MLKEM_HW_HEADERS = $(SRCDIR)mlkem/mlkem_hw.h 
# COMMON
LIB_COMMON_SOURCES = $(SRCDIR)common/mmio.c $(SRCDIR)common/extra_func.c
LIB_COMMON_HEADERS = $(SRCDIR)common/mmio.h $(SRCDIR)common/extra_func.c $(SRCDIR)common/conf.h
# SE-QUBIP HEADER
LIB_HEADER = ../se-qubip.h

# LIBRARY SOURCES & HEADERS
LIB_SOURCES = $(LIB_COMMON_SOURCES) $(LIB_SHA3_HW_SOURCES) $(LIB_SHA2_HW_SOURCES) $(LIB_EDDSA_HW_SOURCES) $(LIB_X25519_HW_SOURCES) $(LIB_TRNG_HW_SOURCES) $(LIB_MLKEM_HW_SOURCES)
LIB_HEADERS = $(LIB_COMMON_HEADERS) $(LIB_SHA3_HW_HEADERS) $(LIB_SHA2_HW_HEADERS) $(LIB_EDDSA_HW_HEADERS) $(LIB_X25519_HW_HEADERS) $(LIB_TRNG_HW_HEADERS) $(LIB_MLKEM_HW_HEADERS) $(LIB_HEADER)

#DEMO
DEMO_SOURCES =	$(SRCDIR_DEMO)demo_sha3.c \
				$(SRCDIR_DEMO)demo_sha2.c \
				$(SRCDIR_DEMO)demo_eddsa.c \
				$(SRCDIR_DEMO)demo_x25519.c \
				$(SRCDIR_DEMO)demo_trng.c \
				$(SRCDIR_DEMO)demo_mlkem.c \
				$(SRCDIR_DEMO)test_x25519.c \
				$(SRCDIR_DEMO)test_func.c

DEMO_SPEED_SOURCES =	$(SRCDIR_DEMO)demo_sha3_speed.c \
						$(SRCDIR_DEMO)demo_sha2_speed.c \
						$(SRCDIR_DEMO)demo_eddsa_speed.c \
						$(SRCDIR_DEMO)demo_mlkem_speed.c \
						$(SRCDIR_DEMO)demo_trng_speed.c \
						$(SRCDIR_DEMO)test_func.c

DEMO_HEADERS =	demo.h $(SRCDIR_DEMO)test_func.h

SOURCES = $(LIB_SOURCES) $(DEMO_SOURCES)
SOURCES_SPEED = $(LIB_SOURCES) $(DEMO_SPEED_SOURCES)
HEADERS = $(LIB_HEADERS) $(DEMO_HEADERS)

# PROGRAMS
demo-all-pynqz2: $(SOURCES) demo.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES) demo.c $(LDFLAGS_DEMO) -D$(BOARD_PYNQ)

demo-build-pynqz2: $(DEMO_SOURCES) demo.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SOURCES) demo.c $(LDFLAGS_DEMO_BUILD) -D$(BOARD_PYNQ)

demo-speed-all-pynqz2: $(SOURCES) demo_speed.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES) demo_speed.c $(LDFLAGS_DEMO_SPEED) -D$(BOARD_PYNQ)

demo-speed-build-pynqz2: $(DEMO_SPEED_SOURCES) demo_speed.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SPEED_SOURCES) demo_speed.c $(LDFLAGS_DEMO_SPEED_BUILD) $(LDFLAGS_LIB_OPENSSL) -D$(BOARD_PYNQ)
	$(export)

demo-all-zcu: $(SOURCES) demo.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES) demo.c $(LDFLAGS_DEMO) -D$(BOARD_ZCU)

demo-build-zcu: $(DEMO_SOURCES) demo.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SOURCES) demo.c $(LDFLAGS_DEMO_BUILD) -D$(BOARD_ZCU)

demo-speed-all-zcu: $(SOURCES) demo_speed.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES) demo_speed.c $(LDFLAGS_DEMO) -D$(BOARD_ZCU)

demo-speed-build-zcu: $(DEMO_SOURCES) demo_speed.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SOURCES) demo_speed.c $(LDFLAGS_DEMO_BUILD) $(LDFLAGS_LIB_OPENSSL) -D$(BOARD_ZCU)

export:	
	echo "export LD_LIBRARY_PATH=$$LD_LIBRARY_PATH:/home/xilinx/se-qubip/se-qubip/build"
	echo "export LD_LIBRARY_PATH=$$LD_LIBRARY_PATH:/home/xilinx/openssl/"


.PHONY: all demo clean

# CLEAN
clean:
	-rm demo
