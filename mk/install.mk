# DESTDIR variable for arch makepkg

.PHONY: install

install: build man
	install -Dm755 $(TARGET) $(DESTDIR)$(BIN_DIR)
ifeq ($(MAN_PAGES_ENABLED), 1)
	install -d $(DESTDIR)$(MAN_DIR)/man1
	install -d $(DESTDIR)$(MAN_DIR)/man5
	install -m644 $(DOC_DIR)/$(TARGET).1.gz $(DESTDIR)$(MAN_DIR)/man1/$(TARGET).1.gz
	install -m644 $(DOC_DIR)/$(TARGET).5.gz $(DESTDIR)$(MAN_DIR)/man5/$(TARGET).5.gz
else
	@echo $(MAN_PAGES_DISABLED_MSG)
endif
