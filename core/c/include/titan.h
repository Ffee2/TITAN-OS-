#ifndef TITAN_H
#define TITAN_H

#define TITAN_VERSION "0.2.0"
#define TITAN_AUTHOR "BARATH"
#define TITAN_NAME "TITAN OS"

void titan_heading(const char *name);
void titan_log_error(const char *message);
const char *titan_platform_name(void);

void titan_show_info(void);
void titan_show_cpu(void);
void titan_show_memory(void);
void titan_show_storage(void);
void titan_show_network(void);
void titan_show_processes(void);
void show_battery(void);

#endif
