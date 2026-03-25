.PHONY: demo build

$(TARGET):
	@$(BASH_XPG) $(SCRIPTS_DIR)/build.sh

demo: $(TARGET)
	@$(BASH_XPG) $(SCRIPTS_DIR)/generate_demo.sh

build: $(TARGET)
