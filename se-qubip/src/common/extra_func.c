#include "extra_func.h"

void swapEndianness(unsigned char *data, size_t size)
{
    size_t i;
    unsigned char temp;

    for (i = 0; i < size / 2; ++i)
    {
        temp = data[i];
        data[i] = data[size - 1 - i];
        data[size - 1 - i] = temp;
    }
}

void seed_rng()
{
    srand((unsigned int)time(NULL)); // Initialization, should only be called once.
}

void gen_priv_key(unsigned char *priv_key, unsigned int priv_len)
{
    unsigned int r;    // Returns a pseudo-random integer between 0 and RAND_MAX.

    for (int i = 0; i < priv_len / sizeof(int); i++)
    {
        r = rand();
        // printf("r = 0x%08X\n", r);

        memcpy(priv_key + i*sizeof(int), &r, sizeof(int));
    }

    /*
    printf("priv_key = 0x");

    for (int i = 0; i < priv_len; i++)
    {
        printf("%02X", *(priv_key + i));
    }
    printf("\n");
    */
}

void print_progress_bar(int percentage, float ETA_time)
{
    const char *color;
    if (percentage < 33)
    {
        color = "\033[1;31m"; // Red
    }
    else if (percentage < 66)
    {
        color = "\033[1;33m"; // Yellow
    }
    else
    {
        color = "\033[1;32m"; // Green
    }

    int pos = (percentage * BAR_WIDTH) / 100;

    // Save cursor position
    printf("\033[s");

    // Move cursor to bottom
    // printf("\033[%dB", EXTRA_LINES + 1);

    // Clear the line
    // printf("\033[2K");

    // Print the progress bar
    printf("%s[", color); // Set color
    for (int i = 0; i < BAR_WIDTH; ++i)
    {
        if (i < pos)
        {
            printf("#");
        }
        else if (i == pos)
        {
            printf(">");
        }
        else
        {
            printf(" ");
        }
    }
    printf("] %d%% | ETA: %4.2f s\033[0m", percentage, ETA_time); // Reset color and print percentage

    // Restore cursor position
    printf("\033[u");

    // printf("] %d%% | ETA: %4.2f s\033[0m\r", percentage, ETA_time);

    fflush(stdout);
}

unsigned long long Wtime() {
    struct timeval time_val;
    gettimeofday(&time_val, NULL);
    return time_val.tv_sec * 1000000 + time_val.tv_usec;
}