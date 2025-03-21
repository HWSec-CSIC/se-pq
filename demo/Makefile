# COMPILER
CC=/usr/bin/cc -fPIC

# INTERFACE (AXI or I2C or I2C_STM32)
INTERFACE = I2C

# BOARD (PYNQZ2 or ZCU104)
BOARD = ZCU104

# COMPILER FLAGS
ifeq ($(INTERFACE), AXI)
	LDFLAGS_DEMO = -lm -lpynq -lcma
	LDFLAGS_DEMO_BUILD = -lm -lpynq -lcma -L../se-qubip/build/ -lsequbip 
	LDFLAGS_DEMO_INSTALL = -lm -lpynq -lcma -lsequbip 
	CFLAGS_DEMO = 
else ifeq ($(INTERFACE), I2C)
	LDFLAGS_DEMO = -lm 
	LDFLAGS_DEMO_BUILD = -lm -L../se-qubip/build/ -lsequbip 
	CFLAGS_DEMO = 
else
	@echo "ERROR: SELECT INTERFACE TYPE!"
endif	

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
LIB_HEADER = ../se-qubip.h

# LIBRARY SOURCES & HEADERS
LIB_SOURCES = $(LIB_COMMON_SOURCES) $(LIB_SHA3_HW_SOURCES) $(LIB_SHA2_HW_SOURCES) $(LIB_EDDSA_HW_SOURCES) $(LIB_X25519_HW_SOURCES) $(LIB_TRNG_HW_SOURCES) $(LIB_AES_HW_SOURCES) $(LIB_MLKEM_HW_SOURCES)
LIB_HEADERS = $(LIB_COMMON_HEADERS) $(LIB_SHA3_HW_HEADERS) $(LIB_SHA2_HW_HEADERS) $(LIB_EDDSA_HW_HEADERS) $(LIB_X25519_HW_HEADERS) $(LIB_TRNG_HW_HEADERS) $(LIB_AES_HW_HEADERS) $(LIB_MLKEM_HW_HEADERS) $(LIB_HEADER)

#DEMO
SRC_DEMO = src/

DEMO_SOURCES =	$(SRC_DEMO)demo_aes.c \
				$(SRC_DEMO)demo_eddsa.c \
				$(SRC_DEMO)demo_x25519.c \
				$(SRC_DEMO)demo_mlkem.c \
				$(SRC_DEMO)demo_sha2.c \
				$(SRC_DEMO)demo_sha3.c \
				$(SRC_DEMO)demo_trng.c \
				$(SRC_DEMO)test_func.c

DEMO_SPEED_SOURCES =	$(SRC_DEMO)demo_aes_speed.c \
						$(SRC_DEMO)demo_sha2_speed.c \
						$(SRC_DEMO)demo_sha3_speed.c \
						$(SRC_DEMO)demo_eddsa_speed.c \
						$(SRC_DEMO)demo_x25519_speed.c \
						$(SRC_DEMO)demo_mlkem_speed.c \
						$(SRC_DEMO)demo_trng_speed.c \
						$(SRC_DEMO)test_func.c

DEMO_ACC_SOURCES =		$(SRC_DEMO)demo_aes_acc.c \
						$(SRC_DEMO)demo_sha3_acc.c \
						$(SRC_DEMO)demo_sha2_acc.c \
						$(SRC_DEMO)demo_eddsa_acc.c \
						$(SRC_DEMO)demo_x25519_acc.c \
						$(SRC_DEMO)demo_mlkem_acc.c \
						$(SRC_DEMO)demo_trng_acc.c \
						$(SRC_DEMO)test_func.c

DEMO_HEADERS = $(SRC_DEMO)demo.h $(SRC_DEMO)test_func.h

SOURCES = $(LIB_SOURCES) $(DEMO_SOURCES)
HEADERS = $(LIB_HEADERS) $(DEMO_HEADERS)

SOURCES_SPEED = $(LIB_SOURCES) $(DEMO_SPEED_SOURCES)
HEADERS_SPEED = $(LIB_HEADERS) $(DEMO_HEADERS)

SOURCES_ACC = $(LIB_SOURCES) $(DEMO_ACC_SOURCES)
HEADERS_ACC = $(LIB_HEADERS) $(DEMO_HEADERS)

# PROGRAMS
demo-all: $(SOURCES) demo.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES) demo.c $(LDFLAGS_DEMO) -D$(BOARD) -D$(INTERFACE)

demo-build: $(DEMO_SOURCES) demo.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SOURCES) demo.c $(LDFLAGS_DEMO_BUILD) -D$(BOARD) -D$(INTERFACE)

demo-install: $(DEMO_SOURCES) demo.c $(DEMO_HEADERS)
	$(CC) -o $@ $(DEMO_SOURCES) demo.c $(LDFLAGS_DEMO_INSTALL) -D$(BOARD) -D$(INTERFACE) -DSEQUBIP_INST

demo-speed-all: $(SOURCES_SPEED) demo_speed.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES_SPEED) demo_speed.c $(LDFLAGS_DEMO) -D$(BOARD) -D$(INTERFACE)

demo-speed-build: $(DEMO_SPEED_SOURCES) demo_speed.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SPEED_SOURCES) demo_speed.c $(LDFLAGS_DEMO_BUILD) -D$(BOARD) -D$(INTERFACE)

demo-speed-install: $(DEMO_SPEED_SOURCES) demo_speed.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO_BUILD) $(DEMO_SPEED_SOURCES) demo_speed.c $(LDFLAGS_DEMO_INSTALL) -D$(BOARD) -D$(INTERFACE) -DSEQUBIP_INST

demo-acc-openssl-all: $(SOURCES_ACC) demo_acc.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES_ACC) demo_acc.c $(LDFLAGS_DEMO) -lcryptoapi -D$(BOARD) -D$(INTERFACE)

demo-acc-mbedtls-all: $(SOURCES_ACC) demo_acc.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES_ACC) demo_acc.c $(LDFLAGS_DEMO) -lcryptoapimbedtls -D$(BOARD) -D$(INTERFACE)

demo-acc-alt-all: $(SOURCES_ACC) demo_acc.c $(HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(SOURCES_ACC) demo_acc.c $(LDFLAGS_DEMO) -lcryptoapialt -D$(BOARD) -D$(INTERFACE)

demo-acc-openssl-build: $(DEMO_ACC_SOURCES) demo_acc.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(DEMO_ACC_SOURCES) demo_acc.c $(LDFLAGS_DEMO_BUILD) -lcryptoapi -D$(BOARD) -D$(INTERFACE)

demo-acc-mbedtls-build: $(DEMO_ACC_SOURCES) demo_acc.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(DEMO_ACC_SOURCES) demo_acc.c $(LDFLAGS_DEMO_BUILD) -lcryptoapimbedtls -D$(BOARD) -D$(INTERFACE)

demo-acc-alt-build: $(DEMO_ACC_SOURCES) demo_acc.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(DEMO_ACC_SOURCES) demo_acc.c $(LDFLAGS_DEMO_BUILD) -lcryptoapialt -D$(BOARD) -D$(INTERFACE)

demo-acc-openssl-install: $(DEMO_ACC_SOURCES) demo_acc.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(DEMO_ACC_SOURCES) demo_acc.c $(LDFLAGS_DEMO_INSTALL) -lcryptoapi -D$(BOARD) -D$(INTERFACE) -DSEQUBIP_INST

demo-acc-mbedtls-install: $(DEMO_ACC_SOURCES) demo_acc.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(DEMO_ACC_SOURCES) demo_acc.c $(LDFLAGS_DEMO_INSTALL) -lcryptoapimbedtls -D$(BOARD) -D$(INTERFACE) -DSEQUBIP_INST

demo-acc-alt-install: $(DEMO_ACC_SOURCES) demo_acc.c $(DEMO_HEADERS)
	$(CC) -o $@ $(CFLAGS_DEMO) $(DEMO_ACC_SOURCES) demo_acc.c $(LDFLAGS_DEMO_INSTALL) -lcryptoapialt -D$(BOARD) -D$(INTERFACE) -DSEQUBIP_INST

.PHONY: all demo clean

# CLEAN
clean:
	-rm demo-*
