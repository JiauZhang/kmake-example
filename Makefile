NAME = kmake-example

srctree := $(CURDIR)
objtree := $(CURDIR)
src := $(srctree)
obj := $(objtree)

export srctree objtree

# Beautify output
include $(srctree)/kmake/Kmake.cout

# That's our default target when none is given on the command line
PHONY := _all
_all:

KBUILD_BUILTIN := 1
export KBUILD_BUILTIN

# Cancel implicit rules on top Makefile
$(CURDIR)/Makefile Makefile: ;

_all: kmake-example

include $(srctree)/kmake/Kbuild.include
include $(srctree)/kmake/subarch.include

# configure compile tools and flags
CROSS_COMPILE :=
include $(srctree)/kmake/Kmake.compiler
NOSTDINC_FLAGS :=

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

rm-files += include/config include/generated \
	.config .config.old kmake-example

# [rm-files] specify the files or generated directories you want to delete
# [clean-dirs] specify the directories you want to clean and
# you can use [clean-files] to specify special files you want to delete in subdir.
include $(srctree)/kmake/Kmake.clean

endif # config-build

PHONY += FORCE
FORCE:

# Declare the contents of the .PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)