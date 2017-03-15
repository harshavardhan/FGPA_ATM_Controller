#!/bin/sh
cd $HOME/3rd
wget http://cznic.dl.sourceforge.net/project/mobilechessboar/avr-gcc%20snapshots%20%28Win32%29/avr-gcc-4.8_2013-03-06_mingw32.zip
unzip avr-gcc-4.8_2013-03-06_mingw32.zip
mv avr-gcc-4.8_2013-03-06_mingw32 avr-gcc
cd avr-gcc/bin
wget --no-check-certificate https://dl.dropboxusercontent.com/u/80983693/dfu-programmer.exe
echo 'You can now add ${HOME}/3rd/avr-gcc/bin to your path and start compiling:'
echo
echo '$ export PATH=${PATH}:${HOME}/3rd/avr-gcc/bin'
echo '$ avr-gcc --version'
echo 'avr-gcc.exe (GCC) 4.8.0 20130306 (experimental)'
echo '$ dfu-programmer.exe --version'
echo 'dfu-programmer 0.6.2'
