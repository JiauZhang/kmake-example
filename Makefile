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

$(info makecmdgoals: $(MAKECMDGOALS))
include $(srctree)/kmake/Kmake.config

core-y := init/
libs-y := lib/
ARCH_MAKEFILE := $(srctree)/arch/Makefile

# head-y core-y drivers-y libs-y
include $(srctree)/kmake/Kmake.build

rm-files += include/config include/generated \
	.config .config.old kmake-example

# [rm-files] specify the files or generated directories you want to delete
# [clean-dirs] specify the directories you want to clean and
# you can use [clean-files] to specify special files you want to delete in subdir.
include $(srctree)/kmake/Kmake.clean

PHONY += FORCE
FORCE:

# Declare the contents of the .PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)