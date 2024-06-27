CC=/usr/bin/cc -O3

OPENSSL_DIR = /opt/openssl/

#LDFLAGS= -lcrypto -lpynq -lcma -lpthread -lm
LDFLAGS= -lcrypto -lpthread -lm -lpynq -lcma
CFLAGS = 

BLDDIR = se-qubip/build/
SRCDIR = se-qubip/src/

LIB_SHA3_HW_SOURCES = $(SRCDIR)sha3/sha3_shake_hw.c
LIB_SHA3_HW_HEADERS = $(SRCDIR)sha3/sha3_shake_hw.h
LIB_SHA2_HW_SOURCES = $(SRCDIR)sha2/sha2_hw.c
LIB_SHA2_HW_HEADERS = $(SRCDIR)sha2/sha2_hw.h
LIB_COMMON_SOURCES = $(SRCDIR)common/mmio.c
LIB_COMMON_HEADERS = $(SRCDIR)common/mmio.h $(SRCDIR)common/conf.h

LIB_HEADER = se-qubip.h

LIB_SOURCES = $(LIB_COMMON_SOURCES) $(LIB_SHA3_HW_SOURCES) $(LIB_SHA2_HW_SOURCES)
LIB_HEADERS = $(LIB_COMMON_HEADERS) $(LIB_SHA3_HW_HEADERS) $(LIB_SHA2_HW_HEADERS) $(LIB_HEADER)

SOURCES = $(LIB_SOURCES)
HEADERS = $(LIB_HEADERS) $(LIB_HEADER)

build: $(SOURCES) $(HEADERS)
	mkdir -p $(BLDDIR)
	$(CC) -shared -Wl,-soname,libsequbip.so -o $(BLDDIR)libsequbip.so $(SOURCES) $(LDFLAGS)
	ar rcs $(BLDDIR)libsequbip.a $(BLDDIR)libsequbip.so

.PHONY: build

clean:
	-rm -r $(BLDDIR)
