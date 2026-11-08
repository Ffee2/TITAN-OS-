#include <stdio.h>
#include "titan.h"

void titan_heading(const char *name)
{
    printf("\n");
    printf("========================================\n");
    printf("          TITAN OS :: %s\n", name);
    printf("========================================\n");
}

void titan_log_error(const char *message)
{
    fprintf(stderr, "[TITAN ERROR] %s\n", message);
}
