# COMPILER
CC=/usr/bin/cc -O3

# BOARD
BOARD = PYNQZ2

# OPENSSL DIRECTORY
OPENSSL_DIR = /opt/openssl/

# COMPILER FLAGS
#LDFLAGS= -lcrypto -lpynq -lcma -lpthread -lm
LDFLAGS= -lcrypto -lpthread -lm -lpynq -lcma
CFLAGS = 

# BUILD & SOURCE DIRECTORY
BLDDIR = se-qubip/build/
SRCDIR = se-qubip/src/

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
# AES
LIB_AES_HW_SOURCES = $(SRCDIR)aes/aes_hw.c 
LIB_AES_HW_HEADERS = $(SRCDIR)aes/aes_hw.h 
# COMMON
LIB_COMMON_SOURCES = $(SRCDIR)common/mmio.c $(SRCDIR)common/extra_func.c
LIB_COMMON_HEADERS = $(SRCDIR)common/mmio.h $(SRCDIR)common/extra_func.h $(SRCDIR)common/conf.h
# SE-QUBIP HEADER
LIB_HEADER = se-qubip.h

# LIBRARY SOURCES & HEADERS
LIB_SOURCES = $(LIB_COMMON_SOURCES) $(LIB_SHA3_HW_SOURCES) $(LIB_SHA2_HW_SOURCES) $(LIB_EDDSA_HW_SOURCES) $(LIB_X25519_HW_SOURCES) $(LIB_TRNG_HW_SOURCES) $(LIB_AES_HW_SOURCES)
LIB_HEADERS = $(LIB_COMMON_HEADERS) $(LIB_SHA3_HW_HEADERS) $(LIB_SHA2_HW_HEADERS) $(LIB_EDDSA_HW_HEADERS) $(LIB_X25519_HW_HEADERS) $(LIB_TRNG_HW_HEADERS) $(LIB_AES_HW_HEADERS) $(LIB_HEADER)

SOURCES = $(LIB_SOURCES)
HEADERS = $(LIB_HEADERS) $(LIB_HEADER)

# BUILD
build: $(SOURCES) $(HEADERS)
	mkdir -p $(BLDDIR)
	$(CC) -shared -Wl,-soname,libsequbip.so -o $(BLDDIR)libsequbip.so $(SOURCES) $(LDFLAGS) -D$(BOARD)
	ar rcs $(BLDDIR)libsequbip.a $(BLDDIR)libsequbip.so

.PHONY: build

# CLEAN 
clean:
	-rm -r $(BLDDIR)
