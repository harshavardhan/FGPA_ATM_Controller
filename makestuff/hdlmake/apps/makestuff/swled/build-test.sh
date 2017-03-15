#!/bin/bash

HDL=$(basename $(pwd))
mkdir -p log
rm -f log/*
(../../../../../bin/hdlmake.py -t ../../templates/epp/${HDL} -b nexys2-1200 -p fpga prom 2>&1) > log/epp-nexys2-1200.log
ls -l *.xsvf *.svf *.bit *.bin >> log/epp-nexys2-1200.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/epp/${HDL} -b ep2c5 2>&1) > log/ep2c5.log
ls -l *.xsvf *.svf *.bit *.bin >> log/ep2c5.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/fx2all/${HDL} -b nexys2-1200 -p fpga prom 2>&1) > log/fx2-nexys2-1200.log
ls -l *.xsvf *.svf *.bit *.bin >> log/fx2-nexys2-1200.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/fx2all/${HDL} -b nexys2-500 -p fpga prom 2>&1) > log/nexys2-500.log
ls -l *.xsvf *.svf *.bit *.bin >> log/nexys2-500.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/fx2all/${HDL} -b s3board -p fpga prom 2>&1) > log/s3board.log
ls -l *.xsvf *.svf *.bit *.bin >> log/s3board.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/fx2all/${HDL} -b xylo-l -p fpga 2>&1) > log/xylo-l.log
ls -l *.xsvf *.svf *.bit *.bin >> log/xylo-l.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/fx2all/${HDL} -b atlys -p fpga 2>&1) > log/atlys.log
ls -l *.xsvf *.svf *.bit *.bin >> log/atlys.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/fx2all/${HDL} -b nexys3 -p fpga 2>&1) > log/nexys3.log
ls -l *.xsvf *.svf *.bit *.bin >> log/nexys3.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/fx2all/${HDL} -b aes220 2>&1) > log/aes220.log
ls -l *.xsvf *.svf *.bit *.bin >> log/aes220.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/fx2min/${HDL} -b lx9 -p fpga 2>&1) > log/lx9.log
ls -l *.xsvf *.svf *.bit *.bin >> log/lx9.log 2> /dev/null
../../../../../bin/hdlmake.py -c
(../../../../../bin/hdlmake.py -t ../../templates/fx2min/${HDL} -b ep3c16 2>&1) > log/ep3c16.log
ls -l *.xsvf *.svf *.bit *.bin >> log/ep3c16.log 2> /dev/null
../../../../../bin/hdlmake.py -c
