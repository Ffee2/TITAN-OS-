#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <net/if.h>
#include "titan.h"

static void show_interface_stats(const char *interface)
{
    FILE *file = fopen("/proc/net/dev", "r");

    if (!file) {
        printf("Traffic data : unavailable\n");
        return;
    }

    char line[512];
    char name[128];

    unsigned long long rx_bytes, rx_packets, rx_errors, rx_drop;
    unsigned long long tx_bytes, tx_packets, tx_errors, tx_drop;

    fgets(line, sizeof(line), file);
    fgets(line, sizeof(line), file);

    while (fgets(line, sizeof(line), file)) {
        int count = sscanf(line,
            " %127[^:]: %llu %llu %llu %llu %*llu %*llu %*llu %*llu %llu %llu %llu %llu",
            name, &rx_bytes, &rx_packets, &rx_errors, &rx_drop,
            &tx_bytes, &tx_packets, &tx_errors, &tx_drop);

        if (count == 9 && strcmp(name, interface) == 0) {
            printf("Received     : %.2f MB\n",
                   rx_bytes / 1048576.0);
            printf("Transmitted  : %.2f MB\n",
                   tx_bytes / 1048576.0);
            printf("RX packets   : %llu\n", rx_packets);
            printf("TX packets   : %llu\n", tx_packets);
            printf("RX errors    : %llu\n", rx_errors);
            printf("TX errors    : %llu\n", tx_errors);
            break;
        }
    }

    fclose(file);
}

static void show_interface_state(const char *interface)
{
    char path[256];
    char state[64] = "unknown";

    snprintf(path, sizeof(path),
             "/sys/class/net/%s/operstate", interface);

    FILE *file = fopen(path, "r");

    if (file) {
        if (fgets(state, sizeof(state), file)) {
            state[strcspn(state, "\r\n")] = '\0';
        }
        fclose(file);
    }

    printf("State        : %s\n", state);
}

void titan_show_network(void)
{
    struct ifaddrs *interfaces;
    struct ifaddrs *item;

    titan_heading("NETWORK ENGINE");

    if (getifaddrs(&interfaces) != 0) {
        titan_log_error("Unable to read network interfaces");
        return;
    }

    int found = 0;

    for (item = interfaces; item != NULL; item = item->ifa_next) {
        if (!item->ifa_name)
            continue;

        int already_printed = 0;

        for (struct ifaddrs *previous = interfaces;
             previous != item; previous = previous->ifa_next) {
            if (previous->ifa_name &&
                strcmp(previous->ifa_name, item->ifa_name) == 0) {
                already_printed = 1;
                break;
            }
        }

        if (already_printed)
            continue;

        found = 1;

        printf("\nInterface    : %s\n", item->ifa_name);
        show_interface_state(item->ifa_name);

        for (struct ifaddrs *address = interfaces;
             address != NULL; address = address->ifa_next) {

            if (!address->ifa_addr || !address->ifa_name ||
                strcmp(address->ifa_name, item->ifa_name) != 0)
                continue;

            char ip[INET6_ADDRSTRLEN];

            if (address->ifa_addr->sa_family == AF_INET) {
                struct sockaddr_in *ipv4 =
                    (struct sockaddr_in *)address->ifa_addr;

                if (inet_ntop(AF_INET, &ipv4->sin_addr,
                              ip, sizeof(ip)))
                    printf("IPv4 address : %s\n", ip);
            }
            else if (address->ifa_addr->sa_family == AF_INET6) {
                struct sockaddr_in6 *ipv6 =
                    (struct sockaddr_in6 *)address->ifa_addr;

                if (inet_ntop(AF_INET6, &ipv6->sin6_addr,
                              ip, sizeof(ip)))
                    printf("IPv6 address : %s\n", ip);
            }
        }

        show_interface_stats(item->ifa_name);
        printf("----------------------------------------\n");
    }

    if (!found)
        printf("No network interfaces found.\n");

    freeifaddrs(interfaces);
}
