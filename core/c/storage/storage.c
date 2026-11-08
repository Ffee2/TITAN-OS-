#include <stdio.h>
#include <stdlib.h>
#include <sys/statvfs.h>
#include "titan.h"

void titan_show_storage(void)
{
    struct statvfs fs;
    const char *home = getenv("HOME");

    titan_heading("STORAGE ENGINE");

    if (!home || statvfs(home, &fs) != 0) {
        titan_log_error("Storage information unavailable");
        return;
    }

    unsigned long long total =
        (unsigned long long)fs.f_blocks * fs.f_frsize;

    unsigned long long free_space =
        (unsigned long long)fs.f_bavail * fs.f_frsize;

    unsigned long long used = total - free_space;

    printf("Location : %s\n", home);
    printf("Total    : %.2f GB\n", total / 1073741824.0);
    printf("Used     : %.2f GB\n", used / 1073741824.0);
    printf("Free     : %.2f GB\n", free_space / 1073741824.0);
}
