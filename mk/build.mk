.PHONY: demo build

run_sh = $(BASH_XPG) $(SCRIPTS_DIR)/$(1)

ifneq ($(filter fzf-vjour,$(MAKECMDGOALS)),)
$(error Target is not allowed)
endif

$(TARGET):
	@$(call run_sh,build.sh)

demo: $(TARGET)
	@$(call run_sh,generate_demo.sh)

build: $(TARGET)
