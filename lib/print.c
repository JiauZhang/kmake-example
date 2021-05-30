#include <stdio.h>
#include <generated/autoconf.h>
#include <print.h>

void print_string()
{
    char *str = CONFIG_X86_STRING;
    printf("autoconf string: %s\n", str);
}