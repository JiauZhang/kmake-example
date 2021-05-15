NAME = kmake-example
MAKEFLAGS += -rR --no-print-directory

ifeq ("$(origin V)", "command line")
  KBUILD_VERBOSE = $(V)
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

ifeq ($(KBUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif

# If the user is running make -s (silent mode), suppress echoing of
# commands
ifneq ($(findstring s,$(filter-out --%,$(MAKEFLAGS))),)
  quiet=silent_
  KBUILD_VERBOSE = 0
endif

export quiet Q KBUILD_VERBOSE

# That's our default target when none is given on the command line
PHONY := _all
_all:

# Cancel implicit rules on top Makefile
$(CURDIR)/Makefile Makefile: ;

_all: all

srctree := $(CURDIR)
objtree := $(CURDIR)
src := $(srctree)
obj := $(objtree)

export srctree objtree

include $(srctree)/kmake/Kbuild.include
include $(srctree)/kmake/subarch.include

# When performing cross compilation for other architectures ARCH shall be set
# to the target architecture. (See arch/* for the possibilities).
# ARCH can be set during invocation of make:
# make ARCH=ia64
# Another way is to have ARCH set in the environment.
# The default ARCH is the host where make is executed.
ARCH ?= $(SUBARCH)
# Architecture as present in compile.h
UTS_MACHINE := $(ARCH)
SRCARCH     := $(ARCH)

KCONFIG_CONFIG ?= .config
export KCONFIG_CONFIG

# SHELL used by kbuild
CONFIG_SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	  else if [ -x /bin/bash ]; then echo /bin/bash; \
	  else echo sh; fi ; fi \
)

HOSTCC       = gcc
HOSTCXX      = g++
HOSTCFLAGS   = -Wall -Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer
HOSTCXXFLAGS = -O2

export KBUILD_USERCFLAGS := -Wall -Wmissing-prototypes -Wstrict-prototypes \
			      -O2 -fomit-frame-pointer -std=gnu89
export KBUILD_USERLDFLAGS :=

# CROSS_COMPILE specify the prefix used for all executables used
# during compilation. Only gcc and related bin-utils executables
# are prefixed with $(CROSS_COMPILE).
# CROSS_COMPILE can be set on the command line
# make CROSS_COMPILE=ia64-linux-
# Alternatively CROSS_COMPILE can be set in the environment.
# Default value for CROSS_COMPILE is not to prefix executables
# Note: Some architectures assign CROSS_COMPILE in their arch/*/Makefile
CPP		= $(CC) -E
CC		= $(CROSS_COMPILE)gcc
LD		= $(CROSS_COMPILE)ld
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
READELF = $(CROSS_COMPILE)readelf
STRIP   = $(CROSS_COMPILE)strip

LEX		= flex
YACC	= bison
AWK		= awk
PERL	= perl
BASH	= bash
KGZIP	= gzip
KBZIP2	= bzip2

LINUXINCLUDE    := \
		-I$(srctree)/arch/$(SRCARCH)/include \
		-I$(objtree)/arch/$(SRCARCH)/include/generated \
		$(USERINCLUDE)

KBUILD_AFLAGS   := -D__ASSEMBLY__ -fno-PIE
KBUILD_CFLAGS   := -Wall -Wundef -Werror=strict-prototypes -Wno-trigraphs \
		   -fno-strict-aliasing -fno-common -fshort-wchar -fno-PIE \
		   -Werror=implicit-function-declaration -Werror=implicit-int \
		   -Werror=return-type -Wno-format-security \
		   -std=gnu89

NOSTDINC_FLAGS += -nostdinc -isystem $(shell $(CC) -print-file-name=include)

export ARCH SRCARCH CONFIG_SHELL BASH HOSTCC CROSS_COMPILE LD CC
export CPP AR NM STRIP OBJCOPY OBJDUMP READELF LEX YACC
export PERL MAKE UTS_MACHINE HOSTCXX
export KGZIP KBZIP2
export KBUILD_CPPFLAGS NOSTDINC_FLAGS LINUXINCLUDE OBJCOPYFLAGS KBUILD_LDFLAGS

# Basic helpers built in kmake/basic/
PHONY += scripts_basic
scripts_basic:
	$(Q)$(MAKE) $(build)=kmake/basic
	$(Q)rm -f .tmp_quiet_recordmcount

include $(srctree)/arch/$(SRCARCH)/Makefile

config: scripts_basic FORCE
	$(Q)$(MAKE) $(build)=kmake/kconfig $@

%config: scripts_basic FORCE
	$(Q)$(MAKE) $(build)=kmake/kconfig $@

PHONY += FORCE
FORCE:

# Declare the contents of the .PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)