////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 12/09/2024
// File Name: intf.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		Interface Driver Header File
//
// Additional Comment:
//
////////////////////////////////////////////////////////////////////////////////////

//-- Include Interfaces
#ifdef I2C
    #include "i2c.h"
#else
    #include "mmio.h"
#endif

//-- Interface Definition
#ifdef I2C
    typedef I2C_FD INTF;
#else  
    typedef MMIO_WINDOW INTF;
#endif

//-- Open and Close Interface
void open_INTF(INTF* interface, size_t address, size_t length);
void close_INTF(INTF interface);

//-- Read & Write
void read_INTF(INTF interface, void* data, size_t offset, size_t size_data);
void write_INTF(INTF interface, void* data, size_t offset, size_t size_data);