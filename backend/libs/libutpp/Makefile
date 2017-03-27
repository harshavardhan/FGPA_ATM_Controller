ROOT    := $(realpath ../..)
DEPS    :=
TYPE    := lib
SUBDIRS := tests

ifeq ($(OS),Windows_NT)
	EXTRA_SRC_DIRS := Win32Utils
	CFLAGS := -DWIN32 -D_CRT_SECURE_NO_WARNINGS -EHa -W4 -nologo -c -errorReport:prompt
else
	EXTRA_SRC_DIRS := PosixUtils
endif

-include $(ROOT)/common/top.mk
