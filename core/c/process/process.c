#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dirent.h>
#include <unistd.h>
#include "titan.h"

#define MAX_PROCESSES 40

static int is_pid(const char *name)
{
    if (!name || !*name)
        return 0;

    for (int i = 0; name[i]; i++) {
        if (!isdigit((unsigned char)name[i]))
            return 0;
    }

    return 1;
}

static int read_process(
    const char *pid,
    char *name,
    size_t name_size,
    char *state,
    long *memory)
{
    char path[256];

    snprintf(path, sizeof(path),
             "/proc/%s/status", pid);

    FILE *file = fopen(path, "r");

    if (!file)
        return 0;

    snprintf(name, name_size, "unknown");
    *state = '?';
    *memory = 0;

    char line[512];

    while (fgets(line, sizeof(line), file)) {
        if (strncmp(line, "Name:", 5) == 0) {
            char *value = line + 5;
            while (*value == ' ' || *value == '\t')
                value++;

            value[strcspn(value, "\r\n")] = '\0';
            snprintf(name, name_size, "%s", value);
        }
        else if (strncmp(line, "State:", 6) == 0) {
            sscanf(line + 6, " %c", state);
        }
        else if (strncmp(line, "VmRSS:", 6) == 0) {
            sscanf(line + 6, " %ld", memory);
        }
    }

    fclose(file);
    return 1;
}

void titan_show_processes(void)
{
    DIR *directory = opendir("/proc");

    titan_heading("PROCESS ENGINE");

    if (!directory) {
        titan_log_error("Cannot access /proc");
        return;
    }

    printf("%-8s %-22s %-7s %s\n",
           "PID", "PROCESS", "STATE", "RAM (MB)");

    printf("------------------------------------------------\n");

    struct dirent *entry;
    int total = 0;
    int displayed = 0;

    while ((entry = readdir(directory)) != NULL) {
        if (!is_pid(entry->d_name))
            continue;

        total++;

        if (displayed >= MAX_PROCESSES)
            continue;

        char name[128];
        char state;
        long memory;

        if (!read_process(entry->d_name,
                          name, sizeof(name),
                          &state, &memory))
            continue;

        printf("%-8s %-22.22s %-7c %.2f\n",
               entry->d_name,
               name,
               state,
               memory / 1024.0);

        displayed++;
    }

    closedir(directory);

    printf("------------------------------------------------\n");
    printf("Detected processes : %d\n", total);
    printf("Displayed processes: %d\n", displayed);
    printf("Display limit      : %d\n", MAX_PROCESSES);
    printf("\nRead-only monitoring enabled.\n");
}
