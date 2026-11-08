#include "titan.h"

const char *titan_platform_name(void)
{
#ifdef __ANDROID__
    return "Android";
#else
    return "Linux";
#endif
}
