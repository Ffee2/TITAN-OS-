#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int get_value(const char *json, const char *key,
                     char *output, size_t size) {
    char search[80];

    snprintf(search, sizeof(search), "\"%s\"", key);

    const char *p = strstr(json, search);
    if (!p) return 0;

    p = strchr(p, ':');
    if (!p) return 0;

    p++;

    while (*p == ' ' || *p == '\t') p++;

    if (*p == '"') {
        p++;
        const char *end = strchr(p, '"');
        if (!end) return 0;

        size_t length = (size_t)(end - p);
        if (length >= size) length = size - 1;

        memcpy(output, p, length);
        output[length] = '\0';
    } else {
        size_t i = 0;
        while (*p && *p != ',' && *p != '}' &&
               i < size - 1) {
            output[i++] = *p++;
        }
        output[i] = '\0';
    }

    return 1;
}

void show_battery(void) {
    FILE *fp = popen("termux-battery-status", "r");

    printf("\n========== TITAN BATTERY MONITOR ==========\n");

    if (!fp) {
        printf("Android battery API unavailable.\n");
        return;
    }

    char json[4096] = {0};
    char line[256];

    while (fgets(line, sizeof(line), fp)) {
        size_t used = strlen(json);
        size_t available = sizeof(json) - used - 1;

        if (available == 0) break;

        strncat(json, line, available);
    }

    int result = pclose(fp);

    if (result != 0 || strlen(json) == 0) {
        printf("Battery data unavailable.\n");
        return;
    }

    char percentage[32] = "Unknown";
    char temperature[32] = "Unknown";
    char voltage[32] = "Unknown";
    char health[32] = "Unknown";
    char status[32] = "Unknown";
    char plugged[32] = "Unknown";
    char technology[32] = "Unknown";
    char cycle[32] = "Unknown";

    get_value(json, "percentage", percentage, sizeof(percentage));
    get_value(json, "temperature", temperature, sizeof(temperature));
    get_value(json, "voltage", voltage, sizeof(voltage));
    get_value(json, "health", health, sizeof(health));
    get_value(json, "status", status, sizeof(status));
    get_value(json, "plugged", plugged, sizeof(plugged));
    get_value(json, "technology", technology, sizeof(technology));
    get_value(json, "cycle", cycle, sizeof(cycle));

    printf("Battery level : %s%%\n", percentage);
    printf("Temperature   : %s C\n", temperature);
    printf("Voltage       : %s mV\n", voltage);
    printf("Health        : %s\n", health);
    printf("Status        : %s\n", status);
    printf("Power source  : %s\n", plugged);
    printf("Technology    : %s\n", technology);
    printf("Cycle count   : %s\n", cycle);

    printf("===========================================\n");
}
