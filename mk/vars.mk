.DEFAULT_GOAL := all

SHELL ?= /usr/bin/env bash
BASH_XPG := bash -O xpg_echo

TARGET := fzf-vjour
BIN_DIR ?= /usr/bin
SCRIPTS_DIR := scripts
DOC_DIR := doc

MAN_DIR ?= /usr/share/man
MAN_SOURCES := $(DOC_DIR)/$(TARGET).1.scd $(DOC_DIR)/$(TARGET).5.scd
MAN_OUTPUTS := $(MAN_SOURCES:.scd=)
MAN_PAGES_ENABLED := 1
MAN_PAGES_DISABLED_MSG := Man pages disabled.

SCDOC := scdoc
SCDOC_ERROR := Error: $(SCDOC) not found.

CLEANUP_TARGETS := $(TARGET) $(DOC_DIR)/$(TARGET).1.gz $(DOC_DIR)/$(TARGET).5.gz
