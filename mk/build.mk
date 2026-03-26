.PHONY: demo build

run_sh = $(BASH_XPG) $(SCRIPTS_DIR)/$(1)

$(TARGET):
	@$(call run_sh,build.sh)

demo: $(TARGET)
	@$(call run_sh,generate_demo.sh)

build: $(TARGET)
