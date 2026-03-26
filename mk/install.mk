# ARCH_PKGDIR variable for arch makepkg

.PHONY: install

bin_install := install -Dm755 $(TARGET) $(1)/$(TARGET)
man_page_install := install -Dm644 $(DOC_DIR)/$(TARGET).$(1).gz $(ARCH_PKGDIR)$(MAN_DIR)/man1/$(TARGET).$(1).gz

install: build man
ifdef DESTDIR
	$(call bin_install,$(ARCH_PKGDIR)$(BIN_DIR))
	$(call man_page_install,1)
	$(call man_page_install,5)
else ifeq ($(MAN_PAGES_ENABLED), 1)
	$(call bin_install,$(BIN_DIR))
	$(call man_page_install,1)
	$(call man_page_install,5)
else
	@echo $(MAN_PAGES_DISABLED_MSG)
	$(call bin_install,$(BIN_DIR))
endif
