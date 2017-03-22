
# build bit file
../../../../../bin/hdlmake.py -t ../../templates/fx2all/vhdl -b atlys -p fpga

# build C file
make -C ../../../../../../apps/flcli deps

# Load FPGALink firmware into the Atlys:
sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -i 1443:0007

# Program the FPGA:
sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -p J:D0D2D3D4:fpga.xsvf

# Write 64KiB of random data to the board:
dd if=/dev/urandom of=random.dat bs=1024 count=64;
# sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -a 'w0 "random.dat";r1;r2' -b

# Do Loop operation
sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -y
sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -a 'w0 "random.dat";r1;r2' -b -y