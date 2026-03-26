# DESTDIR variable for arch makepkg

.PHONY: install

install: build man
ifdef DESTDIR
	install -Dm755 $(TARGET) $(DESTDIR)$(BIN_DIR)/$(TARGET)
	install -Dm644 $(DOC_DIR)/$(TARGET).1.gz $(DESTDIR)$(MAN_DIR)/man1/$(TARGET).1.gz
	install -Dm644 $(DOC_DIR)/$(TARGET).5.gz $(DESTDIR)$(MAN_DIR)/man5/$(TARGET).5.gz
else ifeq ($(MAN_PAGES_ENABLED), 1)
	install -Dm755 $(TARGET) $(BIN_DIR)
	install -Dm644 $(DOC_DIR)/$(TARGET).1.gz $(MAN_DIR)/man1
	install -Dm644 $(DOC_DIR)/$(TARGET).5.gz $(MAN_DIR)/man5
else
	@echo $(MAN_PAGES_DISABLED_MSG)
	install -Dm755 $(TARGET) $(BIN_DIR)
endif
