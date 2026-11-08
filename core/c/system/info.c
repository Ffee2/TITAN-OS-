#include <stdio.h>
#include <sys/utsname.h>
#include "titan.h"

void titan_show_info(void)
{
    struct utsname system;

    titan_heading("SYSTEM CONTROL CENTER");

    printf("OS Name  : %s\n", TITAN_NAME);
    printf("Version  : %s\n", TITAN_VERSION);
    printf("Creator  : %s\n", TITAN_AUTHOR);
    printf("Platform : %s\n", titan_platform_name());

    if (uname(&system) == 0) {
        printf("Kernel   : %s\n", system.release);
        printf("Machine  : %s\n", system.machine);
        printf("System   : %s\n", system.sysname);
    }

    titan_show_cpu();
    titan_show_memory();
}
