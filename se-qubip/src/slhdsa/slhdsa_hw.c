/**
  * @file slhdsa_hw.c
  * @brief SLH-DSA Test File
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
  **/

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 29/07/2025
// File Name: slhdsa_hw.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		SLH-DSA HW Handler Functions
//
////////////////////////////////////////////////////////////////////////////////////

#include "slhdsa_hw.h"

/////////////////////////////////////////////////////////////////////////////////////////////
// GLOBAL VARIABLES DEFINITIONS
/////////////////////////////////////////////////////////////////////////////////////////////

const slh_param_t slh_dsa_shake_128s = {    .alg_id ="SLH-DSA-SHAKE-128s",
    .n= 16, .h= 63, .d= 7, .hp= 9, .a= 12, .k= 14, .lg_w= 4, .m= 30
};

const slh_param_t slh_dsa_shake_128f = {    .alg_id ="SLH-DSA-SHAKE-128f",
    .n= 16, .h= 66, .d= 22, .hp= 3, .a= 6, .k= 33, .lg_w= 4, .m= 34
};

const slh_param_t slh_dsa_shake_192s = {    .alg_id ="SLH-DSA-SHAKE-192s",
    .n= 24, .h= 63, .d= 7, .hp= 9, .a= 14, .k= 17, .lg_w= 4, .m= 39
};

const slh_param_t slh_dsa_shake_192f = {    .alg_id ="SLH-DSA-SHAKE-192f",
    .n= 24, .h= 66, .d= 22, .hp= 3, .a= 8, .k= 33, .lg_w= 4, .m= 42
};

const slh_param_t slh_dsa_shake_256s = {    .alg_id ="SLH-DSA-SHAKE-256s",
    .n= 32, .h= 64, .d= 8, .hp= 8, .a= 14, .k= 22, .lg_w= 4, .m= 47
};

const slh_param_t slh_dsa_shake_256f = {    .alg_id ="SLH-DSA-SHAKE-256f",
    .n= 32, .h= 68, .d= 17, .hp= 4, .a= 9, .k= 35, .lg_w= 4, .m= 49
};

const slh_param_t slh_dsa_sha2_128s = { .alg_id ="SLH-DSA-SHA2-128s",
    .n= 16, .h= 63, .d= 7, .hp= 9, .a= 12, .k= 14, .lg_w= 4, .m= 30
};

const slh_param_t slh_dsa_sha2_128f = { .alg_id ="SLH-DSA-SHA2-128f",
    .n= 16, .h= 66, .d= 22, .hp= 3, .a= 6, .k= 33, .lg_w= 4, .m= 34
};

const slh_param_t slh_dsa_sha2_192s = { .alg_id ="SLH-DSA-SHA2-192s",
    .n= 24, .h= 63, .d= 7, .hp= 9, .a= 14, .k= 17, .lg_w= 4, .m= 39
};

const slh_param_t slh_dsa_sha2_192f = { .alg_id ="SLH-DSA-SHA2-192f",
    .n= 24, .h= 66, .d= 22, .hp= 3, .a= 8, .k= 33, .lg_w= 4, .m= 42
};

const slh_param_t slh_dsa_sha2_256s = { .alg_id ="SLH-DSA-SHA2-256s",
    .n= 32, .h= 64, .d= 8, .hp= 8, .a= 14, .k= 22, .lg_w= 4, .m= 47
};

const slh_param_t slh_dsa_sha2_256f = { .alg_id ="SLH-DSA-SHA2-256f",
    .n= 32, .h= 68, .d= 17, .hp= 4, .a= 9, .k= 35, .lg_w= 4, .m= 49
};

static void sha256_wrapper(unsigned char* in, unsigned int in_len, unsigned char* out, unsigned int out_len, INTF interface) {
    // This wrapper IGNORES the 'out_len' parameter, because the internal
    // SHA-256 function doesn't need it. It just calls the real function.
    (void)out_len; // This tells the compiler "I intentionally ignored this parameter"
    sha_256_hw_func(in, in_len, out, interface);
}

static void sha512_wrapper(unsigned char* in, unsigned int in_len, unsigned char* out, unsigned int out_len, INTF interface) {
    // This wrapper IGNORES the 'out_len' parameter, because the internal
    // SHA-512 function doesn't need it. It just calls the real function.
    (void)out_len; // This tells the compiler "I intentionally ignored this parameter"
    sha_512_hw_func(in, in_len, out, interface);
}

const uint8_t OID_SHA_256[]     = {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01};
const uint8_t OID_SHA_512[]     = {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x03};
const uint8_t OID_SHAKE_128[]   = {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x0B};
const uint8_t OID_SHAKE_256[]   = {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x0C};

const slh_ph_func_t slh_dsa_ph_sha_256 = { .alg_id = "SHA-256",
    .oid = OID_SHA_256,
    .oid_len = sizeof(OID_SHA_256),
    .digest_len = 32,
    .hash_function = sha256_wrapper
};

const slh_ph_func_t slh_dsa_ph_sha_512 = { .alg_id = "SHA-512",
    .oid = OID_SHA_512,
    .oid_len = sizeof(OID_SHA_512),
    .digest_len = 64,
    .hash_function = sha512_wrapper
};

const slh_ph_func_t slh_dsa_ph_shake_128 = { .alg_id = "SHAKE-128",
    .oid = OID_SHAKE_128,
    .oid_len = sizeof(OID_SHAKE_128),
    .digest_len = 32,
    .hash_function = shake128_hw_func
};

const slh_ph_func_t slh_dsa_ph_shake_256 = { .alg_id = "SHAKE-256",
    .oid = OID_SHAKE_256,
    .oid_len = sizeof(OID_SHAKE_256),
    .digest_len = 64,
    .hash_function = shake256_hw_func
};

/////////////////////////////////////////////////////////////////////////////////////////////
// SLH-DSA GENERATE PUBLIC KEY
/////////////////////////////////////////////////////////////////////////////////////////////

void slhdsa_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, uint16_t op_select, const slh_param_t* slh_dsa_parameter, bool ext_key, uint8_t* key_id, INTF interface)
{
    /* if (!ext_key)
    {
        uint8_t key[128];
        secmem_get_key(ID_SLHDSA, *key_id, key, interface);
    } */
    
    //-- se_code = { {32'b0}, {8'b0}, {256, 192, 128, F/S, SHAKE/SHA2, VERIFY, SIGN, GEN_KEYS}, {(16'b)SLH-DSA} }
    uint64_t control = 0;
    while (control != CMD_SE_CODE)
    {
        picorv32_control(interface, &control);
    }
    uint32_t se_op_sel = ((uint16_t) !ext_key << 15) | ((uint16_t) (*key_id << 9)) | op_select;
    uint64_t se_code = (se_op_sel << 16) | SLHDSA_SE_CODE;
    write_INTF(interface, &se_code, PICORV32_DATA_IN, AXI_BYTES);

    //-- Read Public and Private Key
    size_t pk_sz = 2 * slh_dsa_parameter->n;
    size_t sk_sz = 4 * slh_dsa_parameter->n;

    while (control != CMD_SE_READ)
    {
        picorv32_control(interface, &control);
    }

    for (int i = 0; i < pk_sz / AXI_BYTES; i++)
	{
		read_INTF(interface, pub_key + i * AXI_BYTES, PICORV32_DATA_OUT, AXI_BYTES);
	}

    for (int i = 0; i < sk_sz / AXI_BYTES; i++)
	{
		read_INTF(interface, pri_key + i * AXI_BYTES, PICORV32_DATA_OUT, AXI_BYTES);
	}

    while (control != CMD_SE_CODE) 
    {
        picorv32_control(interface, &control);
    }
}

void slhdsa_shake_128_f_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_128 | SLHDSA_SEL_F | SLHDSA_SEL_SHAKE | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_shake_128f, ext_key, key_id, interface);
}

void slhdsa_shake_128_s_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_128 | SLHDSA_SEL_S | SLHDSA_SEL_SHAKE | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_shake_128s, ext_key, key_id, interface);
}

void slhdsa_shake_192_f_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_192 | SLHDSA_SEL_F | SLHDSA_SEL_SHAKE | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_shake_192f, ext_key, key_id, interface);
}

void slhdsa_shake_192_s_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_192 | SLHDSA_SEL_S | SLHDSA_SEL_SHAKE | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_shake_192s, ext_key, key_id, interface);
}

void slhdsa_shake_256_f_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_256 | SLHDSA_SEL_F | SLHDSA_SEL_SHAKE | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_shake_256f, ext_key, key_id, interface);
}

void slhdsa_shake_256_s_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_256 | SLHDSA_SEL_S | SLHDSA_SEL_SHAKE | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_shake_256s, ext_key, key_id, interface);
}

void slhdsa_sha2_128_f_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_128 | SLHDSA_SEL_F | SLHDSA_SEL_SHA2 | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_sha2_128f, ext_key, key_id, interface);
}

void slhdsa_sha2_128_s_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_128 | SLHDSA_SEL_S | SLHDSA_SEL_SHA2 | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_sha2_128s, ext_key, key_id, interface);
}

void slhdsa_sha2_192_f_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_192 | SLHDSA_SEL_F | SLHDSA_SEL_SHA2 | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_sha2_192f, ext_key, key_id, interface);
}

void slhdsa_sha2_192_s_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_192 | SLHDSA_SEL_S | SLHDSA_SEL_SHA2 | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_sha2_192s, ext_key, key_id, interface);
}

void slhdsa_sha2_256_f_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_256 | SLHDSA_SEL_F | SLHDSA_SEL_SHA2 | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_sha2_256f, ext_key, key_id, interface);
}

void slhdsa_sha2_256_s_gen_keys_hw(unsigned char* pri_key, unsigned char* pub_key, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_256 | SLHDSA_SEL_S | SLHDSA_SEL_SHA2 | SLHDSA_SEL_KEY_GEN;
    slhdsa_gen_keys_hw(pri_key, pub_key, op_select, &slh_dsa_sha2_256s, ext_key, key_id, interface);
}

/////////////////////////////////////////////////////////////////////////////////////////////
// SLH-DSA SIGNATURE GENERATION
/////////////////////////////////////////////////////////////////////////////////////////////

void slhdsa_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char *ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, uint16_t op_select, const slh_param_t* slh_dsa_parameter, bool ext_key, uint8_t* key_id, INTF interface)
{
    //-- Check ctx length
    if (ctx_len > 0xFF)
    {
        printf("\nERROR! ctx_len > 255");
        return;
    }
    
    //-- Pre-Hash the Message
    unsigned char ph_msg[ph->digest_len];
    ph->hash_function((unsigned char*) msg, (unsigned int) msg_len, ph_msg, (unsigned int) ph->digest_len, interface);

    /* printf("\nmsg = 0x");
    for (int i = 0; i < msg_len; i++) printf("%02x", msg[i]);

    printf("\nph_msg = 0x");
    for (int i = 0; i < ph->digest_len; i++) printf("%02x", ph_msg[i]); */

    const unsigned int M_len        = 2 + ctx_len + ph->oid_len + ph->digest_len;
    const unsigned int M_packages   = (M_len >> 3) + 1;
    unsigned char M[M_packages * 8];
    memset(M, 0, M_packages * 8);

    M[0] = 0x01;
    M[1] = ctx_len;
    memcpy(M + 2, ctx, ctx_len);
    memcpy(M + 2 + ctx_len, ph->oid, ph->oid_len);
    memcpy(M + 2 + ctx_len + ph->oid_len, ph_msg, ph->digest_len);

    /* printf("\nM = 0x");
    for (int i = 0; i < 2 + ctx_len + ph->oid_len + ph->digest_len; i++) printf("%02x", M[i]); */
    
    //-- se_code = { {(32'b)M_len}, {8'b0}, {256, 192, 128, F/S, SHAKE/SHA2, VERIFY, SIGN, GEN_KEYS}, {(16'b)SLH-DSA} }
    uint64_t control = 0;
    while (control != CMD_SE_CODE)
    {
        picorv32_control(interface, &control);
    }
    uint32_t se_op_sel = ((uint16_t) !ext_key << 15) | ((uint16_t) (*key_id << 9)) | op_select;
    uint64_t se_code = (((uint64_t) M_len) << 32) | (se_op_sel << 16) | SLHDSA_SE_CODE;
    write_INTF(interface, &se_code, PICORV32_DATA_IN, AXI_BYTES);

    //-- Send Message
    while (control != CMD_SE_WRITE)
    {
        picorv32_control(interface, &control);
    }

    for (int i = 0; i < M_packages; i++)
    {
        write_INTF(interface, (unsigned char*) M + i*AXI_BYTES, PICORV32_DATA_IN, AXI_BYTES);
    }

    /* printf("\n\nm_len = %d\n\n", M_len);

    printf("\n\nmsg = ");
    for (int i = 0; i < M_len; i < i++) printf("%02X", M[i]);
    printf("\n\n") */;

    //-- Send Private Key
    size_t sk_packages = 4 * slh_dsa_parameter->n / AXI_BYTES;

    if (ext_key)
    {
        for (int i = 0; i < sk_packages; i++)
        {
            write_INTF(interface, (unsigned char*) pri_key + i*AXI_BYTES, PICORV32_DATA_IN, AXI_BYTES);
        }
    }

    //-- Receive Signature
    size_t packages_read    = 0;
    size_t sig_packages     = (*sig_len >> 3) + 1;
    size_t sig_blocks       = sig_packages / (FIFO_OUT_DEPTH - 2);
    size_t sig_packages_rem = sig_packages % (FIFO_OUT_DEPTH - 2);

    for (size_t i = 0; i < sig_blocks; i++)
    {
        picorv32_control(interface, &control);
        while (control != CMD_SE_READ)
        {
            picorv32_control(interface, &control);
        }

        for (size_t j = 0; j < FIFO_OUT_DEPTH - 2; j++)
        {
            read_INTF(interface, sig + (j + packages_read) * AXI_BYTES, PICORV32_DATA_OUT, AXI_BYTES);
        }
        packages_read += FIFO_OUT_DEPTH - 2;
    }

    picorv32_control(interface, &control);
    while (control != CMD_SE_READ)
    {
        picorv32_control(interface, &control);
    }
    for (size_t i = 0; i < sig_packages_rem; i++)
    {
        read_INTF(interface, sig + (i + packages_read) * AXI_BYTES, PICORV32_DATA_OUT, AXI_BYTES);
    }
    packages_read += sig_packages_rem;

    /* printf("\npackages_read = %d", packages_read);
    printf("\nsig = 0x");
    for (int i = 0; i < *sig_len; i++) printf("%02x", sig[i]); */

    while (control != CMD_SE_CODE) 
    {
        picorv32_control(interface, &control);
    }
}

void slhdsa_shake_128_f_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 17088;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_128 | SLHDSA_SEL_F | SLHDSA_SEL_SHAKE | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_shake_128f, ext_key, key_id, interface);
}

void slhdsa_shake_128_s_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 7856;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_128 | SLHDSA_SEL_S | SLHDSA_SEL_SHAKE | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_shake_128s, ext_key, key_id, interface);
}

void slhdsa_shake_192_f_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 35664;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_192 | SLHDSA_SEL_F | SLHDSA_SEL_SHAKE | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_shake_192f, ext_key, key_id, interface);
}

void slhdsa_shake_192_s_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 16224;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_192 | SLHDSA_SEL_S | SLHDSA_SEL_SHAKE | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_shake_192s, ext_key, key_id, interface);
}

void slhdsa_shake_256_f_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 49856;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_256 | SLHDSA_SEL_F | SLHDSA_SEL_SHAKE | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_shake_256f, ext_key, key_id, interface);
}

void slhdsa_shake_256_s_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 29792;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_256 | SLHDSA_SEL_S | SLHDSA_SEL_SHAKE | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_shake_256s, ext_key, key_id, interface);
}

void slhdsa_sha2_128_f_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 17088;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_128 | SLHDSA_SEL_F | SLHDSA_SEL_SHA2 | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_sha2_128f, ext_key, key_id, interface);
}

void slhdsa_sha2_128_s_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 7856;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_128 | SLHDSA_SEL_S | SLHDSA_SEL_SHA2 | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_sha2_128s, ext_key, key_id, interface);
}

void slhdsa_sha2_192_f_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 35664;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_192 | SLHDSA_SEL_F | SLHDSA_SEL_SHA2 | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_sha2_192f, ext_key, key_id, interface);
}

void slhdsa_sha2_192_s_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 16224;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_192 | SLHDSA_SEL_S | SLHDSA_SEL_SHA2 | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_sha2_192s, ext_key, key_id, interface);
}

void slhdsa_sha2_256_f_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 49856;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_256 | SLHDSA_SEL_F | SLHDSA_SEL_SHA2 | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_sha2_256f, ext_key, key_id, interface);
}

void slhdsa_sha2_256_s_ph_sign_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pri_key, unsigned char* sig, unsigned int* sig_len, bool ext_key, uint8_t* key_id, INTF interface)
{
    *sig_len = 29792;
    uint16_t op_select = SLHDSA_SEL_DETERMINISTIC | SLHDSA_SEL_256 | SLHDSA_SEL_S | SLHDSA_SEL_SHA2 | SLHDSA_SEL_SIGN;
    slhdsa_ph_sign_hw(ph, msg, msg_len, ctx, ctx_len, pri_key, sig, sig_len, op_select, &slh_dsa_sha2_256s, ext_key, key_id, interface);
}

/////////////////////////////////////////////////////////////////////////////////////////////
// SLGH-DSA SIGNATURE VERIFICATION
/////////////////////////////////////////////////////////////////////////////////////////////

void slhdsa_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char *ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, uint16_t op_select, const slh_param_t* slh_dsa_parameter, bool ext_key, uint8_t* key_id, INTF interface)
{
    //-- Check ctx length
    if (ctx_len > 0xFF)
    {
        printf("\nERROR! ctx_len > 255");
        return;
    }
    
    //-- Pre-Hash the Message
    unsigned char ph_msg[ph->digest_len];
    ph->hash_function((unsigned char*) msg, (unsigned int) msg_len, ph_msg, (unsigned int) ph->digest_len, interface);

    /* printf("\nmsg = 0x");
    for (int i = 0; i < msg_len; i++) printf("%02x", msg[i]);

    printf("\nph_msg = 0x");
    for (int i = 0; i < ph->digest_len; i++) printf("%02x", ph_msg[i]); */

    const unsigned int M_len        = 2 + ctx_len + ph->oid_len + ph->digest_len;
    const unsigned int M_packages   = (M_len >> 3) + 1;
    unsigned char M[M_packages * 8];
    memset(M, 0, M_packages * 8);

    M[0] = 0x01;
    M[1] = ctx_len;
    memcpy(M + 2, ctx, ctx_len);
    memcpy(M + 2 + ctx_len, ph->oid, ph->oid_len);
    memcpy(M + 2 + ctx_len + ph->oid_len, ph_msg, ph->digest_len);

    /* printf("\nM = 0x");
    for (int i = 0; i < 2 + ctx_len + ph->oid_len + ph->digest_len; i++) printf("%02x", M[i]); */
    
    //-- se_code = { {(32'b)M_len}, {8'b0}, {256, 192, 128, F/S, SHAKE/SHA2, VERIFY, SIGN, GEN_KEYS}, {(16'b)SLH-DSA} }
    uint64_t received_signal;
    uint64_t control = 0;
    while (control != CMD_SE_CODE)
    {
        picorv32_control(interface, &control);
    }
    uint32_t se_op_sel = ((uint16_t) !ext_key << 15) | ((uint16_t) (*key_id << 9)) | op_select;
    uint64_t se_code = (((uint64_t) M_len) << 32) | (se_op_sel << 16) | SLHDSA_SE_CODE;
    write_INTF(interface, &se_code, PICORV32_DATA_IN, AXI_BYTES);

    //-- Send Message
    while (control != CMD_SE_WRITE)
    {
        picorv32_control(interface, &control);
    }

    for (int i = 0; i < M_packages; i++)
    {
        write_INTF(interface, (unsigned char*) M + i*AXI_BYTES, PICORV32_DATA_IN, AXI_BYTES);
    }

    //-- Send Public Key
    size_t pk_packages = 2 * slh_dsa_parameter->n / AXI_BYTES;

    if (ext_key)
    {
        for (int i = 0; i < pk_packages; i++)
        {
            write_INTF(interface, (unsigned char*) pub_key + i*AXI_BYTES, PICORV32_DATA_IN, AXI_BYTES);
        }
    }

    while (control != CMD_SE_WAIT)
    {
        picorv32_control(interface, &control);
        if (control == CMD_SE_WAIT) read_INTF(interface, &received_signal, PICORV32_DATA_OUT, AXI_BYTES); // Send a read signal to continue
    }

    //-- Send Signature
    size_t packages_write   = 0;
    size_t sig_packages     = (sig_len >> 3) + 1;
    size_t sig_blocks       = sig_packages / (FIFO_OUT_DEPTH - 2);
    size_t sig_packages_rem = sig_packages % (FIFO_OUT_DEPTH - 2);

    for (size_t i = 0; i < sig_blocks; i++)
    {
        while (control != CMD_SE_WRITE)
        {
            picorv32_control(interface, &control);
        }

        for (size_t j = 0; j < FIFO_OUT_DEPTH - 2; j++)
        {
            write_INTF(interface, (unsigned char*) sig + (j + packages_write) * AXI_BYTES, PICORV32_DATA_IN, AXI_BYTES);
        }
        packages_write += FIFO_OUT_DEPTH - 2;

        while (control != CMD_SE_WAIT)
        {
            picorv32_control(interface, &control);
            if (control == CMD_SE_WAIT) read_INTF(interface, &received_signal, PICORV32_DATA_OUT, AXI_BYTES); // Send a read signal to continue
        }
    }

    picorv32_control(interface, &control);
    while (control != CMD_SE_WRITE)
    {
        picorv32_control(interface, &control);
    }
    for (size_t i = 0; i < sig_packages_rem; i++)
    {
        write_INTF(interface, (unsigned char*) sig + (i + packages_write) * AXI_BYTES, PICORV32_DATA_IN, AXI_BYTES);
    }
    packages_write += sig_packages_rem;

    while (control != CMD_SE_WAIT)
    {
        picorv32_control(interface, &control);
        if (control == CMD_SE_WAIT) read_INTF(interface, &received_signal, PICORV32_DATA_OUT, AXI_BYTES); // Send a read signal to continue
    }

    //-- Read Result
    uint64_t result_64;

    while (control != CMD_SE_READ)
    {
        picorv32_control(interface, &control);
    }
    read_INTF(interface, &result_64, PICORV32_DATA_OUT, AXI_BYTES);
    
    *result = result_64;

    while (control != CMD_SE_CODE) 
    {
        picorv32_control(interface, &control);
    }
}

void slhdsa_shake_128_f_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_128 | SLHDSA_SEL_F | SLHDSA_SEL_SHAKE | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_shake_128f, ext_key, key_id, interface);
}

void slhdsa_shake_128_s_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_128 | SLHDSA_SEL_S | SLHDSA_SEL_SHAKE | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_shake_128s, ext_key, key_id, interface);
}

void slhdsa_shake_192_f_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_192 | SLHDSA_SEL_F | SLHDSA_SEL_SHAKE | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_shake_192f, ext_key, key_id, interface);
}

void slhdsa_shake_192_s_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_192 | SLHDSA_SEL_S | SLHDSA_SEL_SHAKE | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_shake_192s, ext_key, key_id, interface);
}

void slhdsa_shake_256_f_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_256 | SLHDSA_SEL_F | SLHDSA_SEL_SHAKE | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_shake_256f, ext_key, key_id, interface);
}

void slhdsa_shake_256_s_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_256 | SLHDSA_SEL_S | SLHDSA_SEL_SHAKE | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_shake_256s, ext_key, key_id, interface);
}

void slhdsa_sha2_128_f_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_128 | SLHDSA_SEL_F | SLHDSA_SEL_SHA2 | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_sha2_128f, ext_key, key_id, interface);
}

void slhdsa_sha2_128_s_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_128 | SLHDSA_SEL_S | SLHDSA_SEL_SHA2 | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_sha2_128s, ext_key, key_id, interface);
}

void slhdsa_sha2_192_f_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_192 | SLHDSA_SEL_F | SLHDSA_SEL_SHA2 | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_sha2_192f, ext_key, key_id, interface);
}

void slhdsa_sha2_192_s_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_192 | SLHDSA_SEL_S | SLHDSA_SEL_SHA2 | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_sha2_192s, ext_key, key_id, interface);
}

void slhdsa_sha2_256_f_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_256 | SLHDSA_SEL_F | SLHDSA_SEL_SHA2 | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_sha2_256f, ext_key, key_id, interface);
}

void slhdsa_sha2_256_s_ph_verify_hw(const slh_ph_func_t *ph, const unsigned char* msg, const unsigned int msg_len, const unsigned char* ctx, const unsigned int ctx_len, const unsigned char* pub_key, const unsigned char* sig, const unsigned int sig_len, unsigned int* result, bool ext_key, uint8_t* key_id, INTF interface)
{
    uint16_t op_select = SLHDSA_SEL_256 | SLHDSA_SEL_S | SLHDSA_SEL_SHA2 | SLHDSA_SEL_VERIFY;
    slhdsa_ph_verify_hw(ph, msg, msg_len, ctx, ctx_len, pub_key, sig, sig_len, result, op_select, &slh_dsa_sha2_256s, ext_key, key_id, interface);
}