CC=/usr/bin/cc -O3

OPENSSL_DIR = /opt/openssl/

LDFLAGS_DEMO = -lpthread -lm -lpynq -lcma
LDFLAGS_DEMO_BUILD = -lpthread -lm -lpynq -lcma -L../se-qubip/build/ -lsequbip
CFLAGS_DEMO =

SRCDIR = ../se-qubip/src/

LIB_SHA3_HW_SOURCES = $(SRCDIR)sha3/sha3_shake_hw.c
LIB_SHA3_HW_HEADERS = $(SRCDIR)sha3/sha3_shake_hw.h
LIB_SHA2_HW_SOURCES = $(SRCDIR)sha2/sha2_hw.c
LIB_SHA2_HW_HEADERS = $(SRCDIR)sha2/sha2_hw.h
LIB_COMMON_SOURCES = $(SRCDIR)common/mmio.c
LIB_COMMON_HEADERS = $(SRCDIR)common/mmio.h $(SRCDIR)common/conf.h

LIB_HEADER = ../se-qubip.h

LIB_SOURCES = $(LIB_COMMON_SOURCES) $(LIB_SHA3_HW_SOURCES) $(LIB_SHA2_HW_SOURCES)
LIB_HEADERS = $(LIB_COMMON_HEADERS) $(LIB_SHA3_HW_HEADERS) $(LIB_SHA2_HW_HEADERS) $(LIB_HEADER)

DEMO_SOURCES =	demo_sha3.c \
				demo_sha2.c \
				test_func.c
DEMO_HEADERS =	demo.h test_func.h

SOURCES = $(LIB_SOURCES) $(DEMO_SOURCES)
HEADERS = $(LIB_HEADERS) $(DEMO_HEADERS)

demo-all: $(SOURCES) demo.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES) demo.c $(LDFLAGS_DEMO)

demo-build: $(DEMO_SOURCES) demo.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SOURCES) demo.c $(LDFLAGS_DEMO_BUILD)

demo-speed-all: $(SOURCES) demo_speed.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES) demo_speed.c $(LDFLAGS_DEMO)

demo-speed-build: $(DEMO_SOURCES) demo_speed.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SOURCES) demo_speed.c $(LDFLAGS_DEMO_BUILD)

.PHONY: all demo clean

clean:
	-rm demo
