.PHONY: man man-pages check-scdoc

$(DOC_DIR)/%.1: $(DOC_DIR)/%.1.scd | check-scdoc
	@scdoc < $< > $@
	@gzip $@

$(DOC_DIR)/%.5: $(DOC_DIR)/%.5.scd | check-scdoc
	@scdoc < $< > $@
	@gzip $@

man:
ifeq ($(MAN_PAGES_ENABLED), 1)
	@$(MAKE) man-pages
endif

man-pages: $(MAN_OUTPUTS)

check-scdoc:
	@which $(SCDOC) >/dev/null 2>&1 || (echo $(SCDOC_ERROR); exit 1)
