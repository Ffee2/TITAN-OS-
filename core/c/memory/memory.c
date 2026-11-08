#include <stdio.h>
#include <string.h>
#include "titan.h"

static long titan_read_memory(const char *key)
{
    FILE *file = fopen("/proc/meminfo", "r");

    if (!file)
        return -1;

    char line[256];
    char name[64];
    long value;

    while (fgets(line, sizeof(line), file)) {
        if (sscanf(line, "%63s %ld", name, &value) == 2) {
            if (strcmp(name, key) == 0) {
                fclose(file);
                return value;
            }
        }
    }

    fclose(file);
    return -1;
}

void titan_show_memory(void)
{
    long total = titan_read_memory("MemTotal:");
    long available = titan_read_memory("MemAvailable:");

    titan_heading("MEMORY ENGINE");

    if (total >= 0)
        printf("Total RAM     : %ld MB\n", total / 1024);
    else
        printf("Total RAM     : unavailable\n");

    if (available >= 0)
        printf("Available RAM : %ld MB\n", available / 1024);
    else
        printf("Available RAM : unavailable\n");

    if (total >= 0 && available >= 0)
        printf("Used RAM      : %ld MB\n",
               (total - available) / 1024);
}
