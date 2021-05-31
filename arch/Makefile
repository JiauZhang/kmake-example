machine-{CONFIG_ARCH_ARM} := arch/arm/
machine-{CONFIG_ARCH_X86} := arch/x86/

$(info init-y before add: $(init-y))
$(info CONFIG_ARCH_X86: $(CONFIG_ARCH_X86))
$(info CONFIG_ARCH_ARM: $(CONFIG_ARCH_ARM))
$(info machine-y: $(machine-y))
$(info machine-: $(machine-))
init-y += $(machine-y)
init-y += arch/arm/
$(info init-y after add: $(init-y))