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
//		Interface Driver File
//
// Additional Comment:
//
////////////////////////////////////////////////////////////////////////////////////

#include "intf.h"

//------------------------------------------------------------------
//-- Open and Close Interface
//------------------------------------------------------------------

void open_INTF(INTF* interface, size_t address, size_t length)
{
#ifdef I2C
    open_I2C(interface);
    set_address_I2C(*interface, address);
#else
    createMMIOWindow(interface, address, length);
#endif
}

void close_INTF(INTF interface)
{
#ifdef I2C
    close_I2C(interface);
#else
    closeMMIOWindow(&interface);
#endif
}

//------------------------------------------------------------------
//--Read & Write
//------------------------------------------------------------------

void read_INTF(INTF interface, void* data, size_t offset, size_t size_data)
{
#ifdef I2C
    read_I2C_ull(interface, data, offset, size_data);
#else
    readMMIO(&interface, data, offset, size_data);
#endif
}

void write_INTF(INTF interface, void* data, size_t offset, size_t size_data)
{
#ifdef I2C
    write_I2C_ull(interface, data, offset, size_data);
#else
    writeMMIO(&interface, data, offset, size_data);
#endif
}

