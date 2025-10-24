#include "demo.h"
#include "test_func.h"

void demo_slhdsa_hw(INTF interface, const slh_ph_func_t *ph, const char mode[12], unsigned int verb) 
{
    /* const char* msg_string = "Hello, this is the SE of QUBIP project";
    const char* ctx_string = "";

    const unsigned int len_msg = strlen((const char*) msg_string);// / 2;
    const unsigned int ctx_len = strlen((const char*) ctx_string) / 2;

    unsigned char msg[len_msg]; memset(msg, 0, len_msg); memcpy(msg, msg_string, len_msg); // char2hex((unsigned char*) msg_string, msg);
    unsigned char ctx[ctx_len]; memset(ctx, 0, ctx_len); char2hex((unsigned char*) ctx_string, ctx); */

    const char* msg_string = "83E2301FA8C4AA769966CC5FF396BEEC0DE326DE3A55828EB8C7E4A6EC525AEB5E76C4F655DD11AD025C19127B990436A71CEC73BFE54B48D886FCB972ADD2B27848F8F7CD6609FA57E5C4859D5A14B5805653BE05D333576E915C5ED76893C7E1B66D904F858DFBDAF146F33DB9DA34E5D421";
    const char* ctx_string = "CF117DF49549A4E17421E41E4181CBEA79AB5A6233CBBDF1F090471D3105BAE024B3885354ABC8507B3E8754D5D5DE7EB644BDBC74CA535764D29F5D991F20FB75B9F41FFF822E3768CF2D862322C390EDE03C5101309918D387D5";

    const unsigned int len_msg = strlen((const char*) msg_string) / 2;
    const unsigned int ctx_len = strlen((const char*) ctx_string) / 2;

    unsigned char msg[len_msg]; memset(msg, 0, len_msg); char2hex((unsigned char*) msg_string, msg);
    unsigned char ctx[ctx_len]; memset(ctx, 0, ctx_len); char2hex((unsigned char*) ctx_string, ctx);

    unsigned int result = 1;

    bool is_external      = false;
    uint8_t key_id_128    = 0;
    uint8_t key_id_192    = 1;
    uint8_t key_id_256    = 2;

    static bool is_key_128_ready = false;
    static bool is_key_192_ready = false;
    static bool is_key_256_ready = false;

    unsigned char* pub_key;
    unsigned char* pri_key;
    unsigned int pub_len;
    unsigned int pri_len;

    unsigned char* sig;
    unsigned int sig_len;

    // ---- SLHDSA ---- //
    if (!memcmp(mode, "shake-128-f", 12)) {

        if (!is_key_128_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_128, is_external, NULL, 0, interface);
            is_key_128_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 64; // CRYPTO_SECRETKEYBYTES_SHAKE_128_F;
        pub_len = 32; // CRYPTO_PUBLICKEYBYTES_SHAKE_128_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 17088; // CRYPTO_BYTES_SHAKE_128_F ;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_128_f_gen_keys_hw(pri_key, pub_key, is_external, &key_id_128, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_128_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_128, interface);

        // if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_128_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_128, interface);

        print_result_valid("SLHDSA-SHAKE-128-F", !result);
    }
    
    else if (!memcmp(mode, "shake-128-s", 12)) {

        if (!is_key_128_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_128, is_external, NULL, 0, interface);
            is_key_128_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 64;  // CRYPTO_SECRETKEYBYTES_SHAKE_128_S;
        pub_len = 32;  // CRYPTO_PUBLICKEYBYTES_SHAKE_128_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 7856; // CRYPTO_BYTES_SHAKE_128_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_128_s_gen_keys_hw(pri_key, pub_key, is_external, &key_id_128, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_128_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_128, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_128_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_128, interface);

        print_result_valid("SLHDSA-SHAKE-128-S", !result);
    }

    else if (!memcmp(mode, "shake-192-f", 12)) {

        if (!is_key_192_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_192, is_external, NULL, 0, interface);
            is_key_192_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 96;  // CRYPTO_SECRETKEYBYTES_SHAKE_192_F;
        pub_len = 48;  // CRYPTO_PUBLICKEYBYTES_SHAKE_192_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 35664; // CRYPTO_BYTES_SHAKE_192_F + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_192_f_gen_keys_hw(pri_key, pub_key, is_external, &key_id_192, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_192_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_192, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_192_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_192, interface);

        print_result_valid("SLHDSA-SHAKE-192-F", !result);
    }

    else if (!memcmp(mode, "shake-192-s", 12)) {

        if (!is_key_192_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_192, is_external, NULL, 0, interface);
            is_key_192_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 96;  // CRYPTO_SECRETKEYBYTES_SHAKE_192_S;
        pub_len = 48;  // CRYPTO_PUBLICKEYBYTES_SHAKE_192_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 16224; // CRYPTO_BYTES_SHAKE_192_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_192_s_gen_keys_hw(pri_key, pub_key, is_external, &key_id_192, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_192_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_192, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_192_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_192, interface);

        print_result_valid("SLHDSA-SHAKE-192-S", !result);
    }

    else if (!memcmp(mode, "shake-256-f", 12)) {

        if (!is_key_256_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_256, is_external, NULL, 0, interface);
            is_key_256_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 128;  // CRYPTO_SECRETKEYBYTES_SHAKE_256_F;
        pub_len = 64;  // CRYPTO_PUBLICKEYBYTES_SHAKE_256_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 49856; // CRYPTO_BYTES_SHAKE_256_F + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_256_f_gen_keys_hw(pri_key, pub_key, is_external, &key_id_256, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_256_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_256, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_256_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_256, interface);

        print_result_valid("SLHDSA-SHAKE-256-F", !result);
    }

    else if (!memcmp(mode, "shake-256-s", 12)) {

        if (!is_key_256_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_256, is_external, NULL, 0, interface);
            is_key_256_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 128;  // CRYPTO_SECRETKEYBYTES_SHAKE_256_S;
        pub_len = 64;  // CRYPTO_PUBLICKEYBYTES_SHAKE_256_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 29792; // CRYPTO_BYTES_SHAKE_256_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_256_s_gen_keys_hw(pri_key, pub_key, is_external, &key_id_256, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_256_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_256, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_256_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_256, interface);

        print_result_valid("SLHDSA-SHAKE-256-S", !result);
    }

    if (!memcmp(mode, "sha-2-128-f", 12)) {

        if (!is_key_128_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_128, is_external, NULL, 0, interface);
            is_key_128_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 64; // CRYPTO_SECRETKEYBYTES_SHAKE_128_F;
        pub_len = 32; // CRYPTO_PUBLICKEYBYTES_SHAKE_128_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 17088; // CRYPTO_BYTES_SHAKE_128_F ;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_128_f_gen_keys_hw(pri_key, pub_key, is_external, &key_id_128, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_128_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_128, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_128_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_128, interface);

        print_result_valid("SLHDSA-SHA2-128-F", !result);
    }
    
    else if (!memcmp(mode, "sha-2-128-s", 12)) {

        if (!is_key_128_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_128, is_external, NULL, 0, interface);
            is_key_128_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 64;  // CRYPTO_SECRETKEYBYTES_SHAKE_128_S;
        pub_len = 32;  // CRYPTO_PUBLICKEYBYTES_SHAKE_128_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 7856; // CRYPTO_BYTES_SHAKE_128_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_128_s_gen_keys_hw(pri_key, pub_key, is_external, &key_id_128, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_128_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_128, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_128_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_128, interface);

        print_result_valid("SLHDSA-SHA2-128-S", !result);
    }

    else if (!memcmp(mode, "sha-2-192-f", 12)) {

        if (!is_key_192_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_192, is_external, NULL, 0, interface);
            is_key_192_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 96;  // CRYPTO_SECRETKEYBYTES_SHAKE_192_F;
        pub_len = 48;  // CRYPTO_PUBLICKEYBYTES_SHAKE_192_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 35664; // CRYPTO_BYTES_SHAKE_192_F + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_192_f_gen_keys_hw(pri_key, pub_key, is_external, &key_id_192, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_192_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_192, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_192_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_192, interface);

        print_result_valid("SLHDSA-SHA2-192-F", !result);
    }

    else if (!memcmp(mode, "sha-2-192-s", 12)) {

        if (!is_key_192_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_192, is_external, NULL, 0, interface);
            is_key_192_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 96;  // CRYPTO_SECRETKEYBYTES_SHAKE_192_S;
        pub_len = 48;  // CRYPTO_PUBLICKEYBYTES_SHAKE_192_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 16224; // CRYPTO_BYTES_SHAKE_192_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_192_s_gen_keys_hw(pri_key, pub_key, is_external, &key_id_192, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_192_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_192, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_192_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_192, interface);

        print_result_valid("SLHDSA-SHA2-192-S", !result);
    }

    else if (!memcmp(mode, "sha-2-256-f", 12)) {

        if (!is_key_256_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_256, is_external, NULL, 0, interface);
            is_key_256_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 128;  // CRYPTO_SECRETKEYBYTES_SHAKE_256_F;
        pub_len = 64;  // CRYPTO_PUBLICKEYBYTES_SHAKE_256_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 49856; // CRYPTO_BYTES_SHAKE_256_F + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_256_f_gen_keys_hw(pri_key, pub_key, is_external, &key_id_256, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_256_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_256, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_256_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_256, interface);

        print_result_valid("SLHDSA-SHA2-256-F", !result);
    }

    else if (!memcmp(mode, "sha-2-256-s", 12)) {

        if (!is_key_256_ready && !is_external)
        {
            secmem_store_key(ID_SLHDSA, &key_id_256, is_external, NULL, 0, interface);
            is_key_256_ready = true;
        }

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        pri_len = 128;  // CRYPTO_SECRETKEYBYTES_SHAKE_256_S;
        pub_len = 64;  // CRYPTO_PUBLICKEYBYTES_SHAKE_256_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 29792; // CRYPTO_BYTES_SHAKE_256_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_256_s_gen_keys_hw(pri_key, pub_key, is_external, &key_id_256, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_256_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, is_external, &key_id_256, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_256_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, is_external, &key_id_256, interface);

        print_result_valid("SLHDSA-SHA2-256-S", !result);
    }
    
    free(pri_key);
    free(pub_key);
    free(sig);
}
