CC=/usr/bin/cc -O3

OPENSSL_DIR = /opt/openssl/

LDFLAGS_DEMO = -lpthread -lm -lpynq -lcma
LDFLAGS_DEMO_BUILD = -lpthread -lm -lpynq -lcma -L../se-qubip/build/ -lsequbip
CFLAGS_DEMO =

SRC_DIR = ../se-qubip/src/

LIB_SHA3_HW_SOURCES = $(SRC_DIR)sha3/sha3_shake_hw.c
LIB_SHA3_HW_HEADERS = $(SRC_DIR)sha3/sha3_shake_hw.h
LIB_COMMON_SOURCES = $(SRC_DIR)common/mmio.c
LIB_COMMON_HEADERS = $(SRC_DIR)common/mmio.h

LIB_HEADER = ../se-qubip.h

LIB_SOURCES = $(LIB_COMMON_SOURCES) $(LIB_SHA3_HW_SOURCES)
LIB_HEADERS = $(LIB_COMMON_HEADERS) $(LIB_SHA3_HW_HEADERS) $(LIB_HEADER)

DEMO_SOURCES =	demo_sha3.c \
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
