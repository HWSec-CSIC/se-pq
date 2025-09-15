#include "demo.h"
#include "test_func.h"

void demo_slhdsa_hw(INTF interface, const slh_ph_func_t *ph, const char mode[12], unsigned int verb) 
{
    const char* msg_string = "Hello, this is the SE of QUBIP project";
    const char* ctx_string = "";

    const unsigned int len_msg = strlen((const char*) msg_string);// / 2;
    const unsigned int ctx_len = strlen((const char*) ctx_string) / 2;

    unsigned char msg[len_msg]; memset(msg, 0, len_msg); memcpy(msg, msg_string, len_msg); // char2hex((unsigned char*) msg_string, msg);
    unsigned char ctx[ctx_len]; memset(ctx, 0, ctx_len); char2hex((unsigned char*) ctx_string, ctx);

    unsigned int result = 1;

    // ---- SLHDSA ---- //
    if (!memcmp(mode, "shake-128-f", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 64; // CRYPTO_SECRETKEYBYTES_SHAKE_128_F;
        pub_len = 32; // CRYPTO_PUBLICKEYBYTES_SHAKE_128_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 17088; // CRYPTO_BYTES_SHAKE_128_F ;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_128_f_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_128_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_128_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHAKE-128-F", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }
    
    else if (!memcmp(mode, "shake-128-s", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 64;  // CRYPTO_SECRETKEYBYTES_SHAKE_128_S;
        pub_len = 32;  // CRYPTO_PUBLICKEYBYTES_SHAKE_128_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 7856; // CRYPTO_BYTES_SHAKE_128_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_128_s_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_128_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_128_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHAKE-128-S", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }

    else if (!memcmp(mode, "shake-192-f", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 96;  // CRYPTO_SECRETKEYBYTES_SHAKE_192_F;
        pub_len = 48;  // CRYPTO_PUBLICKEYBYTES_SHAKE_192_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 35664; // CRYPTO_BYTES_SHAKE_192_F + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_192_f_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_192_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_192_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHAKE-192-F", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }

    else if (!memcmp(mode, "shake-192-s", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 96;  // CRYPTO_SECRETKEYBYTES_SHAKE_192_S;
        pub_len = 48;  // CRYPTO_PUBLICKEYBYTES_SHAKE_192_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 16224; // CRYPTO_BYTES_SHAKE_192_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_192_s_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_192_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_192_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHAKE-192-S", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }

    else if (!memcmp(mode, "shake-256-f", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 128;  // CRYPTO_SECRETKEYBYTES_SHAKE_256_F;
        pub_len = 64;  // CRYPTO_PUBLICKEYBYTES_SHAKE_256_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 49856; // CRYPTO_BYTES_SHAKE_256_F + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_256_f_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_256_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_256_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHAKE-256-F", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }

    else if (!memcmp(mode, "shake-256-s", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 128;  // CRYPTO_SECRETKEYBYTES_SHAKE_256_S;
        pub_len = 64;  // CRYPTO_PUBLICKEYBYTES_SHAKE_256_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 29792; // CRYPTO_BYTES_SHAKE_256_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_shake_256_s_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_shake_256_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_shake_256_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHAKE-256-S", !result);

        free(pri_key);
        free(pub_key);
        free(sig);
    }

    if (!memcmp(mode, "sha-2-128-f", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 64; // CRYPTO_SECRETKEYBYTES_SHAKE_128_F;
        pub_len = 32; // CRYPTO_PUBLICKEYBYTES_SHAKE_128_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 17088; // CRYPTO_BYTES_SHAKE_128_F ;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_128_f_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_128_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_128_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHA2-128-F", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }
    
    else if (!memcmp(mode, "sha-2-128-s", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 64;  // CRYPTO_SECRETKEYBYTES_SHAKE_128_S;
        pub_len = 32;  // CRYPTO_PUBLICKEYBYTES_SHAKE_128_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 7856; // CRYPTO_BYTES_SHAKE_128_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_128_s_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_128_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_128_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHA2-128-S", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }

    else if (!memcmp(mode, "sha-2-192-f", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 96;  // CRYPTO_SECRETKEYBYTES_SHAKE_192_F;
        pub_len = 48;  // CRYPTO_PUBLICKEYBYTES_SHAKE_192_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 35664; // CRYPTO_BYTES_SHAKE_192_F + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_192_f_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_192_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_192_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHA2-192-F", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }

    else if (!memcmp(mode, "sha-2-192-s", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 96;  // CRYPTO_SECRETKEYBYTES_SHAKE_192_S;
        pub_len = 48;  // CRYPTO_PUBLICKEYBYTES_SHAKE_192_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 16224; // CRYPTO_BYTES_SHAKE_192_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_192_s_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_192_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_192_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHA2-192-S", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }

    else if (!memcmp(mode, "sha-2-256-f", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 128;  // CRYPTO_SECRETKEYBYTES_SHAKE_256_F;
        pub_len = 64;  // CRYPTO_PUBLICKEYBYTES_SHAKE_256_F;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 49856; // CRYPTO_BYTES_SHAKE_256_F + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_256_f_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_256_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_256_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHA2-256-F", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }

    else if (!memcmp(mode, "sha-2-256-s", 12)) {

        if (verb >= 2) { printf("\n original msg"); show_array(msg, len_msg, 32); }

        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        unsigned char* sig;
        unsigned int sig_len;

        pri_len = 128;  // CRYPTO_SECRETKEYBYTES_SHAKE_256_S;
        pub_len = 64;  // CRYPTO_PUBLICKEYBYTES_SHAKE_256_S;
        pri_key = (unsigned char*) malloc(pri_len);
        pub_key = (unsigned char*) malloc(pub_len);

        sig_len = 29792; // CRYPTO_BYTES_SHAKE_256_S + len_msg;
        sig = (unsigned char*) malloc(sig_len);

        slhdsa_sha2_256_s_gen_keys_hw(pri_key, pub_key, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }

        slhdsa_sha2_256_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, interface);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        slhdsa_sha2_256_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, interface);

        print_result_valid("SLHDSA-SHA2-256-S", !result);

        free(pri_key);
        free(pub_key);
        free(sig);

    }
    
}
