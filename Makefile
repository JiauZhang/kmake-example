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

KBUILD_BUILTIN := 1
export KBUILD_BUILTIN

# Cancel implicit rules on top Makefile
$(CURDIR)/Makefile Makefile: ;

_all: kmake-example

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
CONFIG_SHELL := sh

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
CPP     = $(CC) -E
CC      = $(CROSS_COMPILE)gcc
LD      = $(CROSS_COMPILE)ld
AR      = $(CROSS_COMPILE)ar
NM      = $(CROSS_COMPILE)nm
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
READELF = $(CROSS_COMPILE)readelf
STRIP   = $(CROSS_COMPILE)strip

LEX    = flex
YACC   = bison
AWK    = awk
PERL   = perl
BASH   = bash
KGZIP  = gzip
KBZIP2 = bzip2

LINUXINCLUDE    := \
		-I$(objtree)/include \
		-I$(srctree)/arch/$(SRCARCH)/include \
		-I$(objtree)/arch/$(SRCARCH)/include/generated \
		$(USERINCLUDE)

KBUILD_AFLAGS   := -D__ASSEMBLY__ -fno-PIE
KBUILD_CFLAGS   := -Wall -Wundef -Werror=strict-prototypes -Wno-trigraphs \
		   -fno-strict-aliasing -fno-common -fshort-wchar -fno-PIE \
		   -Werror=implicit-function-declaration -Werror=implicit-int \
		   -Werror=return-type -Wno-format-security \
		   -std=gnu89

# NOSTDINC_FLAGS += -nostdinc -isystem $(shell $(CC) -print-file-name=include)

export ARCH SRCARCH CONFIG_SHELL BASH HOSTCC CROSS_COMPILE LD CC
export CPP AR NM STRIP OBJCOPY OBJDUMP READELF LEX YACC
export PERL MAKE UTS_MACHINE HOSTCXX
export KGZIP KBZIP2
export KBUILD_CPPFLAGS NOSTDINC_FLAGS LINUXINCLUDE OBJCOPYFLAGS KBUILD_LDFLAGS

clean-targets := %clean mrproper cleandocs
no-dot-config-targets := $(clean-targets) \
			 cscope gtags TAGS tags help% %docs check% coccicheck \
			 $(version_h) headers headers_% archheaders archscripts \
			 %asm-generic kernelversion %src-pkg dt_binding_check

no-sync-config-targets := $(no-dot-config-targets)

config-build :=
need-config	:= 1
may-sync-config	:= 1
ifneq ($(filter $(no-dot-config-targets), $(MAKECMDGOALS)),)
	ifeq ($(filter-out $(no-dot-config-targets), $(MAKECMDGOALS)),)
		need-config :=
	endif
endif

ifneq ($(filter $(no-sync-config-targets), $(MAKECMDGOALS)),)
	ifeq ($(filter-out $(no-sync-config-targets), $(MAKECMDGOALS)),)
		may-sync-config :=
	endif
endif

ifneq ($(filter %config,$(MAKECMDGOALS)),)
	config-build := 1
endif

# Basic helpers built in kmake/basic/
PHONY += scripts_basic
scripts_basic:
	$(Q)$(MAKE) $(build)=kmake/basic
	$(Q)rm -f .tmp_quiet_recordmcount

ifdef config-build
include $(srctree)/arch/Makefile

config: scripts_basic FORCE
	$(Q)$(MAKE) $(build)=kmake/kconfig $@

%config: scripts_basic FORCE
	$(Q)$(MAKE) $(build)=kmake/kconfig $@

else # !config-build
-include include/config/auto.conf

init-y := init/
libs-y := lib/

include $(srctree)/arch/Makefile

build-dirs := $(patsubst %/,%,$(init-y) $(libs-y))
build-objs := $(patsubst %/,%/built-in.a,$(init-y) $(libs-y))

clean-dirs := $(sort $(build-dirs) $(patsubst %/,%,$(filter %/, $(init-) $(libs-))))

$(build-objs): $(build-dirs)

kmake-example: $(build-objs)
	@echo "  CC      $@"
	$(Q)$(CC) $(build-objs) -o $@

PHONY += $(build-dirs)
$(build-dirs): prepare
	$(Q)$(MAKE) $(build)=$@ need-builtin=1

quiet_cmd_syncconfig = SYNC    $@
      cmd_syncconfig = $(MAKE) -f $(srctree)/Makefile syncconfig

%/config/auto.conf %/config/auto.conf.cmd %/generated/autoconf.h: $(KCONFIG_CONFIG)
	+$(call cmd,syncconfig)

PHONY += prepare
prepare: include/generated/autoconf.h

clean-dirs := $(addprefix _clean_, $(clean-dirs))
PHONY += $(clean-dirs) clean
$(clean-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)

rm-files += include/config include/generated \
		.config .config.old

quiet_cmd_rmfiles = $(if $(wildcard $(rm-files)),CLEAN   $(wildcard $(rm-files)))
      cmd_rmfiles = rm -rf $(rm-files)

export RCS_FIND_IGNORE := \( -name SCCS -o -name BitKeeper -o -name .svn -o    \
			  -name CVS -o -name .pc -o -name .hg -o -name .git \) \
			  -prune -o

clean: $(clean-dirs)
	$(call cmd,rmfiles)
	@find $(if $(KBUILD_EXTMOD), $(KBUILD_EXTMOD), .) $(RCS_FIND_IGNORE) \
		\( -name '*.[aios]' -o -name '*.ko' -o -name '.*.cmd' \
		-o -name '*.ko.*' \
		-o -name '*.dtb' -o -name '*.dtbo' -o -name '*.dtb.S' -o -name '*.dt.yaml' \
		-o -name '*.dwo' -o -name '*.lst' \
		-o -name '*.su' -o -name '*.mod' \
		-o -name '.*.d' -o -name '.*.tmp' -o -name '*.mod.c' \
		-o -name '*.lex.c' -o -name '*.tab.[ch]' \
		-o -name '*.asn1.[ch]' \
		-o -name '*.symtypes' -o -name 'modules.order' \
		-o -name '.tmp_*.o.*' \
		-o -name '*.c.[012]*.*' \
		-o -name '*.ll' \
		-o -name '*.gcno' \
		-o -name '*.*.symversions' \) -type f -print | xargs rm -f
endif # config-build

PHONY += FORCE
FORCE:

# Declare the contents of the .PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)
