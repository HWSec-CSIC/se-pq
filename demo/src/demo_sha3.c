/**
  * @file demo_sha3.c
  * @brief Validation Test for SHA3 Code
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

#include "demo.h"
#include "test_func.h"

#ifndef OPENSSL
#define SHA224_DIGEST_LENGTH 28
#define SHA256_DIGEST_LENGTH 32
#define SHA384_DIGEST_LENGTH 48
#define SHA512_DIGEST_LENGTH 64
#endif

void demo_sha3_hw(unsigned int verb, INTF interface) {

    // ---- SHA3 ---- //
    unsigned char* input;
    unsigned int len_input;
    unsigned char* md;
    unsigned int len_output;

    unsigned char* exp_res_3_224 = "6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7";
    unsigned char* exp_res_3_256 = "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a";
    unsigned char* exp_res_3_384 = "0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004";
    unsigned char* exp_res_3_512 = "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26";
    unsigned char* exp_res_s_128 = "7f9c2ba4e88f827d616045507605853ed73b8093f6efbc88eb1a6eacfa66ef26";
    unsigned char* exp_res_s_256 = "46b9dd2b0ba88d13233b3feb743eeb243fcd52ea62b81b82b50c27646ed5762fd75dc4ddd8c0f200cb05019d67b592f6fc821c49479ab48640292eacb3b7c4be";

    unsigned char res_3_224[28]; char2hex(exp_res_3_224, res_3_224);
    unsigned char res_3_256[32]; char2hex(exp_res_3_256, res_3_256);
    unsigned char res_3_384[48]; char2hex(exp_res_3_384, res_3_384);
    unsigned char res_3_512[64]; char2hex(exp_res_3_512, res_3_512);
    unsigned char res_s_128[32]; char2hex(exp_res_s_128, res_s_128);
    unsigned char res_s_256[64]; char2hex(exp_res_s_256, res_s_256);

    input = malloc(32);
    input[0] = (unsigned char)('\0');
    len_input = 0;

    /*
    len_input = 9856 / 8;   
    len_output = 1500;
    
    input = (unsigned char*) malloc(len_input);
    unsigned char* char_test_input = "e2f6f200c1ed92da4b529e459fd2e16f862bf51a0e3b094b745de24247f620afcb4bc3239c96edc59358e946edf06d17aa6d1cd934a14f154176152dfa8679925de50338e0418147572e061417bb344f5c49b77ee89d12a9ed339e572dd5cfba606dba27d618d4c95d7bfd95655abd806266cdf07257d971403b84aa280ead8f9c8af0d8c64070b16ee8d4b31ff69013856e66191af82cd40237cf0d32579879d8e5ae32f7e4dd68521d95548cb6366e8d068ae028a8933aface886795d81ae0de26fb1fb32aa157d1c14862f5c336fb42d8422de38e970bf1a9b6a297bbba2c74f4e087403a46e5b37cf3c4a24418216c8c95e894d3bfb0af7061a5812501c563f76450e73d5479bff8a062db626547d2ca8cfa839e948ffcca91589b40751472d88f63f05b517dbeda5624e845a4d73d392e49f8189d11a05f4fa32c34a07f6b3f69a8a3bbc75879cd1ef210145d38758183be3b69629e62d8a26e7e290a6f14d3fb0748863d72b577ffb49df818d2424b934193b86b9f0bdd93a1d746394d373d4c6926e33c333d800152d5185e0d6c3f67bb4a2d417a6315292480b3b77f9a2564b486fb4b03d8912cb4019db651ba040612a6f26b9932296cdfc1990c6f06314cd2b0f6f24a4d5289c368aea906f5437830f02c716240c064bbe120be83420c0ba9ecfbb970656a1f655474be94e5a3c6fb6f06dc3f55831a9e2a6f5725185ca923823229dde882f6830b167d6352cdf75d6da63297381a9572e2af5fbc4eca2f27b9c4c9f99e411706d6bd6edb0468133d3034fed2b22cdd1d52075cb0adfda49cdbd9212d4e5089d4fd911a65c21d238201d9c5578b61fb89c2a0d868fd9e106c2e98badfc25654d7c8b9086756942d1628bc11908b63f69c79a15a4e06547c7efb2a1b79c0fc81f57f5ec04b86743ce0ed0769e479d7d640c1336bc98fc8efba89b7cc6111ea171869a7cb771b6555c898df56bb1f68a45ce07e924162a17108226656017dc71e27cfbdb055dd1182b6706e5f7e43bc67d71fa9571e45880a500c5f40bfcb3b9f0af9c7f74b931dca92bedc0c93ae7b279bc6dd42c90125c37a90cb1205c5f0a0a92fee29c307343644ca51e563284eec8f1d41dca85e1fa36ef6d2553a318b2cecb95acd24fffcccb5dcf4735679ddbf9b6cfeac24231fb215869b90c5d8b748bbde326bd6441d96cb3ced3dd568cfa7a7fa3b3aa61accf955884f4b10821afefee89f8b419e409c6f3265cb46beccad9b10210f9409cf7f1743150f82f65c559d1dc8b6cdd40de58a0584a612437ed85ff6d8b257b9cf4d4400166283fe265680c6d673e2b02b7902fe7155a2bf8a30dcf487ab58f27569c20779cf7b6020078f2af04be8f84360c16555605dfa9bbdf8525683fe7b69dd7ba067dbd2e5f172b3933fc54775fca2ad825750aabb57889c576ec1b01e52b155130810f155419fd247ea6967efff48b09ca0acf3cc6698b14cf7edd8a1d8eb3aa783f53e78ba94d58f1abfb02ef35ab1fc57fc9ff371f51d791890ddcda49511a501122216025ba5b3f7508bf981de97eba5c916f920a8ca26fa31276a5eb6c255a9f006f6c1fc28fba8a35e1951de4cafb299bfa61ab89e9bc5581e40ae5734ffa41650e1a07d48af564092570a61b790a5f704c1082d831fa08d2a163a7f51eb190c6a9f46e8ec1628b090795470c0d8a6684c14911060fcb359b3b6ad360061315bbaf85d44fc79477abf";
    char2hex(char_test_input, input);
    */

    // len_input = 2681;       // 2681-2687 it FAILS!!!


    // ---- sha3_224 ---- //
    /*
    md = malloc(SHA224_DIGEST_LENGTH);
    sha3_224(input, len_input, md);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA224_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_3_224, SHA224_DIGEST_LENGTH, 32);
    }
    print_result_valid("SHA3-224", memcmp(md, res_3_224, SHA224_DIGEST_LENGTH));
    free(md);
    */
    // ---- sha3_256 ---- //
    md = malloc(SHA256_DIGEST_LENGTH);
    sha3_256_hw(input, len_input, md, interface);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA256_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_3_256, SHA256_DIGEST_LENGTH, 32);
    }
    print_result_valid("SHA3-256", memcmp(md, res_3_256, SHA256_DIGEST_LENGTH));
    free(md);
    /*
    // ---- sha3_384 ---- //
    md = malloc(SHA384_DIGEST_LENGTH);
    sha3_384(input, len_input, md);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA384_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_3_384, SHA384_DIGEST_LENGTH, 32);
    }
    print_result_valid("SHA3-384", memcmp(md, res_3_384, SHA384_DIGEST_LENGTH));
    free(md);
    */
    // ---- sha3_512 ---- //
    md = malloc(SHA512_DIGEST_LENGTH);
    sha3_512_hw(input, len_input, md, interface);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA512_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_3_512, SHA512_DIGEST_LENGTH, 32);
    }
    print_result_valid("SHA3-512", memcmp(md, res_3_512, SHA512_DIGEST_LENGTH));
    free(md);

    // ---- shake_128 ---- //
    md = malloc(32);
    shake_128_hw(input, len_input, md, 32, interface);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, 32, 32);
        printf("\n Expected Result: ");  show_array(res_s_128, 32, 32);
    }
    print_result_valid("SHAKE-128", memcmp(md, res_s_128, 32));
    free(md);

    // ---- shake_256 ---- //
    md = malloc(64);
    shake_256_hw(input, len_input, md, 64, interface);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, 64, 32);
        printf("\n Expected Result: ");  show_array(res_s_256, 64, 32);
    }
    print_result_valid("SHAKE-256", memcmp(md, res_s_256, 64));
    free(md);
}