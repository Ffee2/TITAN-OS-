#include <stdio.h>
#include <string.h>
#include "titan.h"

static void titan_help(void)
{
    titan_heading("COMMAND CENTER");

    printf("info       System information\n");
    printf("cpu        CPU information\n");
    printf("memory     RAM information\n");
    printf("storage    Storage information\n");
    printf("network    Network diagnostics\n");
    printf("processes  Process monitoring\n");
    printf("battery    Battery information\n");
    printf("help       Show commands\n");
    printf("--version  Show version\n");
}

int main(int argc, char *argv[])
{
    if (argc < 2 || strcmp(argv[1], "info") == 0) {
        titan_show_info();
    }
    else if (strcmp(argv[1], "cpu") == 0) {
        titan_show_cpu();
    }
    else if (strcmp(argv[1], "memory") == 0) {
        titan_show_memory();
    }
    else if (strcmp(argv[1], "storage") == 0) {
        titan_show_storage();
    }
    else if (strcmp(argv[1], "network") == 0) {
        titan_show_network();
    }
    else if (strcmp(argv[1], "processes") == 0) {
        titan_show_processes();
    }
    else if (strcmp(argv[1], "battery") == 0) {
        show_battery();
    }
    else if (strcmp(argv[1], "help") == 0) {
        titan_help();
    }
    else if (strcmp(argv[1], "--version") == 0) {
        printf("TITAN OS Native Engine v%s\n", TITAN_VERSION);
        printf("Created by %s\n", TITAN_AUTHOR);
    }
    else {
        titan_log_error("Unknown command. Use: titan-native help");
        return 1;
    }

    return 0;
}
