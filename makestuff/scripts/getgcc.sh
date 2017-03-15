#!/bin/sh
mkdir /var/tmp/mingw
cd /var/tmp/mingw
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.8.1-4/gcc-core-4.8.1-4-mingw32-bin.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.8.1-4/gcc-core-4.8.1-4-mingw32-dll.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/binutils/binutils-2.24/binutils-2.24-1-mingw32-bin.tar.xz/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.8.1-4/gcc-core-4.8.1-4-mingw32-dev.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/gmp/gmp-5.1.2/gmp-5.1.2-1-mingw32-dll.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/mpc/mpc-1.0.1-2/mpc-1.0.1-2-mingw32-dll.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/mpfr/mpfr-3.1.2-2/mpfr-3.1.2-2-mingw32-dll.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/mingw-rt/mingwrt-4.0.3/mingwrt-4.0.3-1-mingw32-dev.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/w32api/w32api-4.0.3/w32api-4.0.3-1-mingw32-dev.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/gettext/gettext-0.18.1.1-2/libintl-0.18.1.1-2-mingw32-dll-8.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/libiconv/libiconv-1.14-3/libiconv-1.14-3-mingw32-dll.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.8.1-4/gcc-c%2B%2B-4.8.1-4-mingw32-dll.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.8.1-4/gcc-c%2B%2B-4.8.1-4-mingw32-dev.tar.lzma/download'
wget 'http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.8.1-4/gcc-c%2B%2B-4.8.1-4-mingw32-bin.tar.lzma/download'

cd /
for i in /var/tmp/mingw/*; do 7za x -so $i | tar xf -; done
rm -rf /var/tmp/mingw
