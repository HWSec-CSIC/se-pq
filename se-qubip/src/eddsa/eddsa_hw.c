////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 13/06/2024
// File Name: eddsa_hw.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		EdDSA HW Handler Functions
//
////////////////////////////////////////////////////////////////////////////////////

#include "eddsa_hw.h"

/////////////////////////////////////////////////////////////////////////////////////////////
// INTERFACE INIT/START & READ/WRITE
/////////////////////////////////////////////////////////////////////////////////////////////

void eddsa25519_init(unsigned long long operation, MMIO_WINDOW ms2xl)
{
    unsigned long long control;
    unsigned long long address;
    unsigned long long data_in;

    //-- General and Interface Reset
    control = (ADD_EDDSA << 32) + EDDSA_INTF_RST + EDDSA_RST_ON;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);

    // printf("Press any key to continue...\n");
    // getchar();

    // Select Operation Mode
    control = (ADD_EDDSA << 32) + EDDSA_INTF_LOAD + EDDSA_RST_ON;
    address = 0;
    data_in = operation;

    writeMMIO(&ms2xl, &address, ADDRESS, AXI_BYTES);
    writeMMIO(&ms2xl, &data_in, DATA_IN, AXI_BYTES);
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);

    control = (ADD_EDDSA << 32) + EDDSA_INTF_OPER + EDDSA_RST_ON;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

void eddsa25519_start(MMIO_WINDOW ms2xl)
{
    unsigned long long control = (ADD_EDDSA << 32) + EDDSA_RST_OFF;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

void eddsa25519_write(unsigned long long address, unsigned long long size,  void *data, unsigned long long reset, MMIO_WINDOW ms2xl)
{
    unsigned long long addr = address;
    unsigned long long control = (reset) ? (ADD_EDDSA << 32) + EDDSA_INTF_LOAD + EDDSA_RST_ON : (ADD_EDDSA << 32) + EDDSA_INTF_LOAD + EDDSA_RST_OFF;

    writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
    writeMMIO(&ms2xl, data, DATA_IN, AXI_BYTES);
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);

    for (int i = 1; i < size; i++)
    {
        addr = address + i;
        writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
        writeMMIO(&ms2xl, data + AXI_BYTES * i, DATA_IN, AXI_BYTES);
    }

    control = (reset) ? (ADD_EDDSA << 32) + EDDSA_INTF_OPER + EDDSA_RST_ON : (ADD_EDDSA << 32) + EDDSA_INTF_OPER + EDDSA_RST_OFF;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

void eddsa25519_read(unsigned long long address, unsigned long long size, void *data, MMIO_WINDOW ms2xl)
{
    unsigned long long control = (ADD_EDDSA << 32) + EDDSA_INTF_READ;
    unsigned long long addr;

    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);

    for (int i = 0; i < size; i++)
    {
        addr = address + i;
        writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
        readMMIO(&ms2xl, data + AXI_BYTES * i, DATA_OUT, AXI_BYTES);
    }

}

/////////////////////////////////////////////////////////////////////////////////////////////
// GENERATE PUBLIC KEY
/////////////////////////////////////////////////////////////////////////////////////////////

void eddsa25519_genkeys_hw(unsigned char **pri_key, unsigned char **pub_key, unsigned int *pri_len, unsigned int *pub_len, MMIO_WINDOW ms2xl)
{

    *pri_len = EDDSA_BYTES;
    *pub_len = EDDSA_BYTES;

    *pri_key = (unsigned char*) malloc(*pri_len);
    *pub_key = (unsigned char*) malloc(*pub_len);

    gen_priv_key(*pri_key, *pri_len);

    /*
    printf("Private = 0x");
    for (int i = 0; i < EDDSA_BYTES; i++)
    {
        printf("%02x", *(*pri_key + i));
    }
    printf("\n");
    */    


    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    unsigned long long info;

    //-- INITIALIZATION: General/Interface Reset & Select Operation
    eddsa25519_init(EDDSA_OP_GEN_KEY, ms2xl);

    //-- Write private value
    eddsa25519_write(EDDSA_ADDR_PRIV, EDDSA_BYTES/AXI_BYTES, *pri_key, EDDSA_RST_ON, ms2xl);

    //-- Start Core
    eddsa25519_start(ms2xl); 

    //-- Detect when finish
    int count = 0;

    while (count < EDDSA_WAIT_TIME)
    {
        eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

        if (info & 0x1)
        {
            // printf("\nexp_RSA PASS!\n\n");
            break;
        }
        else if ((info >> 1) & 0x1)
        {
            printf("\nERROR!\n\n");
        }
        
        count++;
    }
    if (count == EDDSA_WAIT_TIME) printf("GEN_KEY FAIL!: TIMEOUT \t%d\n", count);
    
    count = 0;
    
    //////////////////////////////////////////////////////////////
    // RESULTS
    //////////////////////////////////////////////////////////////
    
    eddsa25519_read(EDDSA_ADDR_SIGPUB, EDDSA_BYTES/AXI_BYTES, *pub_key, ms2xl); 

    swapEndianness(*pub_key, *pub_len);
    
    /*
    printf("Public = 0x");
    for (int i = 0; i < EDDSA_BYTES; i++)
    {
        printf("%02x", *(*pub_key + i));
    }
    printf("\n");
    */

    swapEndianness(*pri_key, *pri_len);
}

/////////////////////////////////////////////////////////////////////////////////////////////
// SIGN
/////////////////////////////////////////////////////////////////////////////////////////////

void eddsa25519_sign_hw(unsigned char *msg, unsigned int msg_len, unsigned char *pri_key, unsigned int pri_len, unsigned char *pub_key, unsigned int pub_len, unsigned char **sig, unsigned int *sig_len, MMIO_WINDOW ms2xl)
{

    if (msg_len > MAX_MSG_LENGTH) 
    {
        printf("\n\n********************************************************************************");
        printf("\nERROR: message length (%i bytes) exceeds MAX_MSG_LENTGH (%i bytes)\n", msg_len, MAX_MSG_LENGTH);
        printf("********************************************************************************\n\n");
        exit(1);
    }
    
    // pri_len, pub_len, and sig_len are not used.
    pri_len = EDDSA_BYTES;
    pub_len = EDDSA_BYTES;
    *sig_len = SHA_BYTES;

    *sig = (unsigned char*) malloc(*sig_len);

    unsigned char MSG[MAX_MSG_LENGTH];
    memset(MSG, 0, MAX_MSG_LENGTH);
    memcpy(MSG, msg, msg_len);

    unsigned char M[BLOCK_BYTES];

    memcpy(&M[0], &MSG[0], BLOCK_BYTES);
    swapEndianness(&M[0], BLOCK_BYTES);

    unsigned long long msg_len_bits = 8 * msg_len;

    /*
    printf("Private = 0x");
    for (int i = 0; i < EDDSA_BYTES; i++)
    {
        printf("%02x", pri_key[i]);
    }
    printf("\n");
    printf("Public = 0x");
    for (int i = 0; i < EDDSA_BYTES; i++)
    {
        printf("%02x", pub_key[i]);
    }
    printf("\n");
    printf("Message = 0x");
    for (int i = 0; i < (msg_len_bits >> 3); i++)
    {
        printf("%02x", msg[i]);
    }
    printf("\n");
    printf("msg_len = 0x%x\n", msg_len);
    printf("\n");
    printf("Len_message_bits = 0x%llx\n", msg_len_bits);
    */

    swapEndianness(pri_key, pri_len);
    swapEndianness(pub_key, pub_len);

    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    unsigned long long block_valid_end  = EDDSA_OP_SIGN + 0x0;
    unsigned long long block_valid_1    = EDDSA_OP_SIGN + 0x1;
    unsigned long long block_valid_2    = EDDSA_OP_SIGN + 0x2;
    unsigned long long info;

    //-- INITIALIZATION: General/Interface Reset & Select Operation
    eddsa25519_init(EDDSA_OP_SIGN, ms2xl);

    // Write private and public value
    eddsa25519_write(EDDSA_ADDR_PRIV, EDDSA_BYTES / AXI_BYTES, pri_key, EDDSA_RST_ON, ms2xl);
    eddsa25519_write(EDDSA_ADDR_PUB, EDDSA_BYTES / AXI_BYTES, pub_key, EDDSA_RST_ON, ms2xl);

    // Write 1st message block and message length
    eddsa25519_write(EDDSA_ADDR_LEN, 1, &msg_len_bits, EDDSA_RST_ON, ms2xl);
    eddsa25519_write(EDDSA_ADDR_MSG, BLOCK_BYTES / AXI_BYTES, &M, EDDSA_RST_ON, ms2xl);

    // Start Core
    eddsa25519_start(ms2xl);

    // Data Blocks
    unsigned long long length = msg_len_bits + 128;

    // printf("Length: %lld bits\n", length);

    unsigned long long blocks_768 = (length < 768) ? 1 : ((length - 768) >> 10) + 1;
    unsigned long long blocks_512 = (length < 512) ? 1 : ((length - 512) >> 10) + 1;
    
    int count = 0;
    int block_odd = 0;

    if (length < 512)
    {
        while (count < EDDSA_WAIT_TIME)
        {
            eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

            if (info & 0x1)
            {
                // printf("\nexp_RSA PASS!\n\n");
                break;
            }
            else if ((info >> 1) & 0x1)
            {
                printf("\nERROR!\n\n");
                exit(1);
            }
            /*
            else if ((info >> 2) & 0x1)
            {
                printf("\nERROR IN HASH!\n\n");
                exit(1);
            }
            */
            count++;
        }

        if (count == EDDSA_WAIT_TIME) printf("SIGN FAIL!: TIMEOUT \t%d\n", count);

        count = 0;
    }
    else if (length >= 768)
    {
        // printf("\nblocks_768 = %lli\n", blocks_768);

        for (int i = 0; i < blocks_768; i++)
        {
            // Detect Block Ready
            while (count < EDDSA_WAIT_TIME)
            {
                eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

                if ((info >> 2) & 0x1)
                {
                    break;
                }
                else if ((info >> 1) & 0x1)
                {
                    printf("\nERROR!\n\n");
                    exit(1);
                }
                count++;
            }

            if (count == EDDSA_WAIT_TIME) printf("LOAD MESSAGE FAIL!: TIMEOUT \t%d\n", count);

            count = 0;

            // Write next message block
            memcpy(&M[0], &MSG[96 + i * 128], BLOCK_BYTES);
            swapEndianness(&M[0], BLOCK_BYTES);

            eddsa25519_write(EDDSA_ADDR_MSG, BLOCK_BYTES / AXI_BYTES, &M, EDDSA_RST_OFF, ms2xl);
            
            // Activate Block Valid
            if (block_odd)
            {
                eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_1, EDDSA_RST_OFF, ms2xl);
                block_odd = 0;
            }
            else 
            {
                eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_2, EDDSA_RST_OFF, ms2xl);
                block_odd = 1;
            }
        }

        while (count < EDDSA_WAIT_TIME)
        {
            eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

            if ((info >> 2) & 0x1)
            {
                break;
            }
            else if ((info >> 1) & 0x1)
            {
                printf("\nERROR!\n\n");
                exit(1);
            }
            count++;
        }

        if (count == EDDSA_WAIT_TIME) printf("LOAD MESSAGE FAIL!: TIMEOUT \t%d\n", count);

        count = 0;

        memcpy(&M[0], &MSG[0], BLOCK_BYTES);
        swapEndianness(&M[0], BLOCK_BYTES);

        eddsa25519_write(EDDSA_ADDR_MSG, BLOCK_BYTES / AXI_BYTES, &M, EDDSA_RST_OFF, ms2xl);

        // Activate Block Valid
        if (block_odd)
        {
            eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_1, EDDSA_RST_OFF, ms2xl);
            block_odd = 0;
        }
        else
        {
            eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_2, EDDSA_RST_OFF, ms2xl);
            block_odd = 1;
        }

        // printf("\nblocks_512 = %lli\n", blocks_512);

        for (int i = 0; i < blocks_512; i++)
        {
            // Detect Block Ready
            while (count < EDDSA_WAIT_TIME)
            {
                eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

                if ((info >> 2) & 0x1)
                {
                    break;
                }
                else if ((info >> 1) & 0x1)
                {
                    printf("\nERROR!\n\n");
                    exit(1);
                }
                count++;
            }

            if (count == EDDSA_WAIT_TIME) printf("LOAD MESSAGE FAIL!: TIMEOUT \t%d\n", count);

            count = 0;
            // Write next message block
            memcpy(&M[0], &MSG[64 + i * 128], BLOCK_BYTES);
            swapEndianness(&M[0], BLOCK_BYTES);

            eddsa25519_write(EDDSA_ADDR_MSG, BLOCK_BYTES / AXI_BYTES, &M, EDDSA_RST_OFF, ms2xl);
            
            // Activate Block Valid
            if (block_odd)
            {
                eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_1, EDDSA_RST_OFF, ms2xl);
                block_odd = 0;
            }
            else
            {
                eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_2, EDDSA_RST_OFF, ms2xl);
                block_odd = 1;
            }
        }

        while (count < EDDSA_WAIT_TIME)
        {
            eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

            if ((info) & 0x1)
            {
                break;
            }
            else if ((info >> 1) & 0x1)
            {
                printf("\nERROR!\n\n");
                exit(1);
            }
            count++;
        }

        if (count == EDDSA_WAIT_TIME) printf("SIGN FAIL!: TIMEOUT \t%d\n", count);

        count = 0;
    }
    else 
    {
        while (count < EDDSA_WAIT_TIME)
        {
            eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

            if ((info >> 2) & 0x1)
            {
                break;
            }
            else if ((info >> 1) & 0x1)
            {
                printf("\nERROR!\n\n");
                exit(1);
            }
            count++;
        }

        if (count == EDDSA_WAIT_TIME) printf("LOAD MESSAGE FAIL!: TIMEOUT \t%d\n", count);

        count = 0;

        if (block_odd)
        {
            eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_1, EDDSA_RST_OFF, ms2xl);
            block_odd = 0;
        }
        else
        {
            eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_2, EDDSA_RST_OFF, ms2xl);
            block_odd = 1;
        }

        // printf("\nblocks_512 = %lli\n", blocks_512);

        for (int i = 0; i < blocks_512; i++)
        {
            // Detect Block Ready
            while (count < EDDSA_WAIT_TIME)
            {
                eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

                if ((info >> 2) & 0x1)
                {
                    break;
                }
                else if ((info >> 1) & 0x1)
                {
                    printf("\nERROR!\n\n");
                    exit(1);
                }
                count++;
            }

            if (count == EDDSA_WAIT_TIME) printf("LOAD MESSAGE FAIL!: TIMEOUT \t%d\n", count);

            count = 0;

            // Write next message block
            memcpy(&M[0], &MSG[64 + i*128], BLOCK_BYTES);
            swapEndianness(&M[0], BLOCK_BYTES);

            eddsa25519_write(EDDSA_ADDR_MSG, BLOCK_BYTES / AXI_BYTES, &M, EDDSA_RST_OFF, ms2xl);
            
            // Activate Block Valid
            if (block_odd)
            {
                eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_1, EDDSA_RST_OFF, ms2xl);
                block_odd = 0;
            }
            else
            {
                eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_2, EDDSA_RST_OFF, ms2xl);
                block_odd = 1;
            }
        }

        while (count < EDDSA_WAIT_TIME)
        {
            eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

            if ((info) & 0x1)
            {
                break;
            }
            else if ((info >> 1) & 0x1)
            {
                printf("\nERROR!\n\n");
                exit(1);
            }
            count++;
        }

        if (count == EDDSA_WAIT_TIME) printf("SIGN FAIL!: TIMEOUT \t%d\n", count);

        count = 0;
    }

    //////////////////////////////////////////////////////////////
    // RESULTS
    //////////////////////////////////////////////////////////////

    eddsa25519_read(EDDSA_ADDR_SIGPUB, SHA_BYTES / AXI_BYTES, *sig, ms2xl);

    swapEndianness(*sig, *sig_len);

    /*
    printf("Signature = 0x");
    for (int i = 0; i < SHA_BYTES; i++)
    {
        printf("%02x", *(*sig + i));
    }
    printf("\n");
    */

    eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_end, EDDSA_RST_OFF, ms2xl);

    swapEndianness(pri_key, pri_len);
    swapEndianness(pub_key, pub_len);
}

/////////////////////////////////////////////////////////////////////////////////////////////
// VERIFICATION
/////////////////////////////////////////////////////////////////////////////////////////////

void eddsa25519_verify_hw(unsigned char *msg, unsigned int msg_len, unsigned char *pub_key, unsigned int pub_len, unsigned char *sig, unsigned int sig_len, unsigned int *result, MMIO_WINDOW ms2xl)
{

    if (msg_len > MAX_MSG_LENGTH)
    {
        printf("\n\n********************************************************************************");
        printf("\nERROR: message length (%i bytes) exceeds MAX_MSG_LENTGH (%i bytes)\n", msg_len, MAX_MSG_LENGTH);
        printf("********************************************************************************\n\n");
        exit(1);
    }

    *result = 0;

    pub_len = EDDSA_BYTES;
    sig_len = SHA_BYTES;

    unsigned char MSG[MAX_MSG_LENGTH];
    memset(MSG, 0, MAX_MSG_LENGTH);
    memcpy(MSG, msg, msg_len);

    unsigned char M[BLOCK_BYTES] = {0};

    memcpy(&M[0], &MSG[0], BLOCK_BYTES);
    swapEndianness(&M[0], BLOCK_BYTES);

    unsigned long long msg_len_bits = 8 * msg_len;

    /*
    printf("Public = 0x");
    for (int i = 0; i < EDDSA_BYTES; i++)
    {
        printf("%02x", pub_key[i]);
    }
    printf("\n");
    printf("Message = 0x");
    for (int i = 0; i < (msg_len_bits >> 3); i++)
    {
        printf("%02x", MSG[i]);
    }
    printf("\n");
    printf("Len_message_bits = 0x%llx\n", msg_len_bits);
    */

    swapEndianness(pub_key, pub_len);
    swapEndianness(sig, sig_len);

    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    unsigned long long block_valid_end  = EDDSA_OP_VERIFY + 0x0;
    unsigned long long block_valid_1    = EDDSA_OP_VERIFY + 0x1;
    unsigned long long block_valid_2    = EDDSA_OP_VERIFY + 0x2;
    unsigned long long info;

    //-- INITIALIZATION: General/Interface Reset & Select Operation
    eddsa25519_init(EDDSA_OP_VERIFY, ms2xl);

    // Write public value
    eddsa25519_write(EDDSA_ADDR_PUB, EDDSA_BYTES / AXI_BYTES, pub_key, EDDSA_RST_ON, ms2xl);

    // Write signature to verify
    eddsa25519_write(EDDSA_ADDR_SIGVER, SHA_BYTES / AXI_BYTES, sig, EDDSA_RST_ON, ms2xl);

    // Write 1st message block and message length
    eddsa25519_write(EDDSA_ADDR_LEN, 1, &msg_len_bits, EDDSA_RST_ON, ms2xl);
    eddsa25519_write(EDDSA_ADDR_MSG, BLOCK_BYTES / AXI_BYTES, &M, EDDSA_RST_ON, ms2xl);

    // Start Core
    eddsa25519_start(ms2xl);

    unsigned long long length = msg_len_bits + 128;

    unsigned long long blocks_512 = (length < 512) ? 1 : ((length - 512) >> 10) + 1;

    int count = 0;
    int block_odd = 0;

    if (length < 512)
    {
        while (count < EDDSA_WAIT_TIME)
        {
            eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

            if (info & 0x1)
            {
                // printf("\nexp_RSA PASS!\n\n");
                break;
            }
            else if ((info >> 1) & 0x1)
            {
                printf("\nERROR!\n\n");
                return;
            }

            count++;
        }
        if (count == EDDSA_WAIT_TIME) printf("VERIFICATION FAIL!: TIMEOUT \t%d\n", count);

        count = 0;
    }
    else
    {
        while (count < EDDSA_WAIT_TIME)
        {
            eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

            if ((info >> 2) & 0x1)
            {
                break;
            }
            else if ((info >> 1) & 0x1)
            {
                printf("\nERROR!\n\n");
                return;
            }
            count++;
        }

        if (count == EDDSA_WAIT_TIME) printf("LOAD MESSAGE FAIL!: TIMEOUT \t%d\n", count);

        count = 0;

        for (int i = 0; i < blocks_512; i++)
        {
            // Write next message block
            memcpy(&M[0], &MSG[64 + i * 128], BLOCK_BYTES);
            swapEndianness(&M[0], BLOCK_BYTES);

            eddsa25519_write(EDDSA_ADDR_MSG, BLOCK_BYTES / AXI_BYTES, &M, EDDSA_RST_OFF, ms2xl);

            // Activate Block Valid
            if (block_odd)
            {
                eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_1, EDDSA_RST_OFF, ms2xl);
                block_odd = 0;
            }
            else
            {
                eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_2, EDDSA_RST_OFF, ms2xl);
                block_odd = 1;
            }

            // Detect Block Ready
            while (count < EDDSA_WAIT_TIME)
            {
                eddsa25519_read(EDDSA_ADDR_CTRL, 1, &info, ms2xl);

                if ((info) & 0x1)
                {
                    break;
                }
                else if ((info >> 2) & 0x1)
                {
                    break;
                }
                else if ((info >> 1) & 0x1)
                {
                    printf("\nERROR!\n\n");
                    exit(1);
                }
                count++;
            }

            if (count == EDDSA_WAIT_TIME) printf("LOAD MESSAGE FAIL!: TIMEOUT \t%d\n", count);

            count = 0;
           
        }
    }

    eddsa25519_write(EDDSA_ADDR_CTRL, 1, &block_valid_end, EDDSA_RST_OFF, ms2xl);

    swapEndianness(pub_key, pub_len);
    swapEndianness(sig, sig_len);

    if (info & 0x1) 
    {
        *result = 1;
        return;
    }
    else 
    {
        return;
    }
}