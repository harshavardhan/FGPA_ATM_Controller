# Make
make deps

echo "Make Deps Complete --------------------------------------"

# Renumaration
sudo ./lin.x64/rel/flcli -v 1d50:602b:0002 -i 1443:0007

echo "Renumeration Complete -----------------------------------"

echo "Starting ATM Service ------------------------------------"

# Run ATM service
 sudo ./lin.x64/rel/flcli -v 1d50:602b:0002 -yl