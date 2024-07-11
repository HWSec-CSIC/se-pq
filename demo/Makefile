# COMPILER
CC=/usr/bin/cc -O3

# BOARD
BOARD = ZCU104

# OPENSSL DIRECTORY
OPENSSL_DIR = /opt/openssl/

# COMPILER FLAGS
LDFLAGS_DEMO = -lpthread -lm -lpynq -lcma
LDFLAGS_DEMO_BUILD = -lpthread -lm -lpynq -lcma -L../se-qubip/build/ -lsequbip 
CFLAGS_DEMO =

# SOURCE DIRECTORY
SRCDIR = ../se-qubip/src/

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
# COMMON
LIB_COMMON_SOURCES = $(SRCDIR)common/mmio.c $(SRCDIR)common/extra_func.c
LIB_COMMON_HEADERS = $(SRCDIR)common/mmio.h $(SRCDIR)common/extra_func.c $(SRCDIR)common/conf.h
# SE-QUBIP HEADER
LIB_HEADER = ../se-qubip.h

# LIBRARY SOURCES & HEADERS
LIB_SOURCES = $(LIB_COMMON_SOURCES) $(LIB_SHA3_HW_SOURCES) $(LIB_SHA2_HW_SOURCES) $(LIB_EDDSA_HW_SOURCES) $(LIB_X25519_HW_SOURCES)
LIB_HEADERS = $(LIB_COMMON_HEADERS) $(LIB_SHA3_HW_HEADERS) $(LIB_SHA2_HW_HEADERS) $(LIB_EDDSA_HW_HEADERS) $(LIB_X25519_HW_HEADERS) $(LIB_HEADER)

#DEMO
DEMO_SOURCES =	demo_sha3.c \
				demo_sha2.c \
				demo_eddsa.c \
				demo_x25519.c \
				test_x25519.c \
				test_func.c
DEMO_HEADERS =	demo.h test_func.h

SOURCES = $(LIB_SOURCES) $(DEMO_SOURCES)
HEADERS = $(LIB_HEADERS) $(DEMO_HEADERS)

# PROGRAMS
demo-all: $(SOURCES) demo.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES) demo.c $(LDFLAGS_DEMO) -D$(BOARD)

demo-build: $(DEMO_SOURCES) demo.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SOURCES) demo.c $(LDFLAGS_DEMO_BUILD) -D$(BOARD)

demo-speed-all: $(SOURCES) demo_speed.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES) demo_speed.c $(LDFLAGS_DEMO) -D$(BOARD)

demo-speed-build: $(DEMO_SOURCES) demo_speed.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SOURCES) demo_speed.c $(LDFLAGS_DEMO_BUILD) -D$(BOARD)

.PHONY: all demo clean

# CLEAN
clean:
	-rm demo
