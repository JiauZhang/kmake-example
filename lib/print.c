#include <stdio.h>
#include <generated/autoconf.h>

void print_string()
{
    printf("%s\n", CONFIG_X86_STRING);
}