# COMPILER
CC=/usr/bin/cc -fPIC

# INTERFACE (AXI or I2C or I2C_STM32)
INTERFACE = I2C

# BOARD (PYNQZ2 or ZCU104)
BOARD = ZCU104

# OPENSSL DIRECTORY
OPENSSL_DIR = /opt/openssl/

# COMPILER FLAGS
ifeq ($(INTERFACE), AXI)
	LDFLAGS_DEMO = -lpthread -lm -lpynq -lcma
	LDFLAGS_DEMO_BUILD = -lpthread -lm -lpynq -lcma -L../se-qubip/build/ -lsequbip 
	CFLAGS_DEMO =
else ifeq ($(INTERFACE), I2C)
	LDFLAGS_DEMO = -lpthread -lm 
	LDFLAGS_DEMO_BUILD = -lpthread -lm -L../se-qubip/build/ -lsequbip 
	CFLAGS_DEMO =
else
	@echo "ERROR: SELECT INTERFACE TYPE!"
endif	

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
# MLKEM
LIB_MLKEM_HW_SOURCES = $(SRCDIR)mlkem/mlkem_hw.c 
LIB_MLKEM_HW_HEADERS = $(SRCDIR)mlkem/mlkem_hw.h 
# COMMON
ifeq ($(INTERFACE), AXI)
	LIB_COMMON_SOURCES = $(SRCDIR)common/intf.c $(SRCDIR)common/mmio.c $(SRCDIR)common/extra_func.c
	LIB_COMMON_HEADERS = $(SRCDIR)common/intf.h $(SRCDIR)common/mmio.h $(SRCDIR)common/extra_func.h $(SRCDIR)common/conf.h
else ifeq ($(INTERFACE), I2C)
	LIB_COMMON_SOURCES = $(SRCDIR)common/intf.c $(SRCDIR)common/i2c.c $(SRCDIR)common/extra_func.c
	LIB_COMMON_HEADERS = $(SRCDIR)common/intf.h $(SRCDIR)common/i2c.h $(SRCDIR)common/extra_func.h $(SRCDIR)common/conf.h
else
	@echo "ERROR: SELECT INTERFACE TYPE!"
endif	
# SE-QUBIP HEADER
LIB_HEADER = se-qubip.h

# LIBRARY SOURCES & HEADERS
LIB_SOURCES = $(LIB_COMMON_SOURCES) $(LIB_SHA3_HW_SOURCES) $(LIB_SHA2_HW_SOURCES) $(LIB_EDDSA_HW_SOURCES) $(LIB_X25519_HW_SOURCES) $(LIB_TRNG_HW_SOURCES) $(LIB_AES_HW_SOURCES) $(LIB_MLKEM_HW_SOURCES)
LIB_HEADERS = $(LIB_COMMON_HEADERS) $(LIB_SHA3_HW_HEADERS) $(LIB_SHA2_HW_HEADERS) $(LIB_EDDSA_HW_HEADERS) $(LIB_X25519_HW_HEADERS) $(LIB_TRNG_HW_HEADERS) $(LIB_AES_HW_HEADERS) $(LIB_MLKEM_HW_HEADERS) $(LIB_HEADER)

SOURCES = $(LIB_SOURCES)
HEADERS = $(LIB_HEADERS) $(LIB_HEADER)

# BUILD
build: $(SOURCES) $(HEADERS)
	mkdir -p $(BLDDIR)
	$(CC) -shared -Wl,-soname,libsequbip.so -o $(BLDDIR)libsequbip.so $(SOURCES) $(LDFLAGS) -D$(BOARD) -D$(INTERFACE)
	ar rcs $(BLDDIR)libsequbip.a $(BLDDIR)libsequbip.so

install:
	cp $(BLDDIR)libsequbip.so /usr/lib/.
	cp $(BLDDIR)libsequbip.a /usr/lib/.
	cp se-qubip.h /usr/include/.
	cp -r se-qubip /usr/include/se-qubip

uninstall: 
	rm -f /usr/lib/libsequbip.so
	rm -f /usr/lib/libsequbip.a
	rm -f /usr/include/se-qubip.h
	rm -rf /usr/include/se-qubip

.PHONY: build

# CLEAN 
clean:
	-rm -r $(BLDDIR)
