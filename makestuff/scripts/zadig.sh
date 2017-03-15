#!/bin/sh
export ZADIG_EXE=zadig.exe
export ZADIG_INI=zadig.ini
cd ${HOME}/3rd
if [ ! -e ${ZADIG_EXE} ]; then
  export URL=http://zadig.akeo.ie/downloads/zadig.exe
  echo "Downloading zadig.exe from ${URL}..."
  wget -qO ${ZADIG_EXE} ${URL}
fi
if [ ! -e ${ZADIG_INI} ]; then
  printf '[device]\r\n  list_all = true\r\n' > zadig.ini
fi
echo "Launching Zadig..."
cmd //c ${ZADIG_EXE}
echo "Done!"
