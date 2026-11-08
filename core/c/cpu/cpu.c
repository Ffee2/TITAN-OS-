#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/utsname.h>
#include "titan.h"

void titan_show_cpu(void)
{
    struct utsname system;
    long cores = sysconf(_SC_NPROCESSORS_ONLN);

    titan_heading("CPU ENGINE");

    if (uname(&system) == 0)
        printf("Architecture : %s\n", system.machine);

    printf("Online cores : %ld\n", cores);

    FILE *file = fopen("/proc/cpuinfo", "r");

    if (!file) {
        printf("CPU model    : unavailable\n");
        return;
    }

    char line[256];

    while (fgets(line, sizeof(line), file)) {
        if (strncmp(line, "Hardware", 8) == 0 ||
            strncmp(line, "model name", 10) == 0 ||
            strncmp(line, "Processor", 9) == 0) {

            char *value = strchr(line, ':');
            printf("CPU model    : %s",
                   value ? value + 1 : line);
            break;
        }
    }

    fclose(file);
}
