#
# Copyright (C) 2011 Chris McClelland
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
ROOT    := $(realpath ../..)
DEPS    := 
TYPE    := dll
SUBDIRS := 
ifeq ($(OS),Windows_NT)
	CFLAGS  := -DHAVE_CONFIG_H -DWIN32 -D_CRT_SECURE_NO_WARNINGS -D BUILD_READLINE_DLL -D strchr=strchr -D _CRT_SECURE_NO_DEPRECATE -D _CRT_NONSTDC_NO_DEPRECATE -EHsc -W3 -WX- -nologo -c -errorReport:prompt -I.
	CC_SRCS := bind.c complete.c funmap.c history.c isearch.c macro.c nls.c rltty.c shell.c text.c util.c xmalloc.c callback.c display.c histexpand.c histsearch.c keymaps.c mbutil.c parens.c savestring.c signals.c tilde.c compat.c histfile.c input.c kill.c misc.c readline.c search.c terminal.c undo.c vi_mode.c
	LINK_EXTRALIBS_REL := advapi32.lib
	LINK_EXTRALIBS_DBG := $(LINK_EXTRALIBS_REL)
	PRE_BUILD := win32-readline
	EXTRA_CLEAN := readline *.c *.h
	OT := all
else
	OT := posix-readline
endif

override: $(OT)

-include $(ROOT)/common/top.mk

win32-readline: readline-5.2-20061112-src.zip
	unzip readline-5.2-20061112-src.zip
	rm -rf manifest
	mv src/readline/5.2/readline-5.2-src/*.c .
	mv src/readline/5.2/readline-5.2-src/*.h .
	mv src/readline/5.2/readline-5.2/msvc/config.h .
	rm -rf src
	mkdir -p readline
	cp -p chardefs.h history.h keymaps.h readline.h rlconf.h rlstdc.h rltypedefs.h tilde.h readline/

readline-5.2-20061112-src.zip:
	wget http://gpsim.sourceforge.net/gpsimWin32/packages/readline-5.2-20061112-src.zip

posix-readline: $(OUTDIR_REL) $(OUTDIR_DBG)
	@if [ ! -e /usr/include/readline ]; then echo 'You need to install the libreadline development package (e.g sudo apt-get install libreadline6-dev)'; exit 1; fi
	echo -lreadline > $(OUTDIR_REL)/libs.txt
	echo -lreadline > $(OUTDIR_DBG)/libs.txt
	touch $(PM)/incs.txt
