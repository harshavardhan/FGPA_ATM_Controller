library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;
-- Code adapted from http://fpga-tutorials.blogspot.in/2012/12/deouncing-push-buttons.html
-- Please see the above site for an excellent description of debouncing logic and
-- the need for this.

entity mod_swled is
	port(
		clk_in       : in  std_logic;
		reset_in     : in  std_logic;

		-- DVR interface -----------------------------------------------------------------------------
		chanAddr_in  : in  std_logic_vector(6 downto 0);  -- the selected channel (0-127)

		-- Host >> FPGA pipe:
		h2fData_in   : in  std_logic_vector(7 downto 0);  -- data lines used when the host writes to a channel
		h2fValid_in  : in  std_logic;                     -- '1' means "on the next clock rising edge, please accept the data on h2fData"
		h2fReady_out : out std_logic;                     -- channel logic can drive this low to say "I'm not ready for more data yet"

		-- Host << FPGA pipe:
		f2hData_out  : out std_logic_vector(7 downto 0);  -- data lines used when the host reads from a channel
		f2hValid_out : out std_logic;                     -- channel logic can drive this low to say "I don't have data ready for you"
		f2hReady_in  : in  std_logic;                     -- '1' means "on the next clock rising edge, put your next byte of data on f2hData"

		-- Peripheral interface ----------------------------------------------------------------------
		sseg_out       : out   std_logic_vector(7 downto 0); -- seven-segment display cathodes (one for each segment)
		anode_out      : out   std_logic_vector(3 downto 0); -- seven-segment display anodes (one for each digit)
		led_out        : out   std_logic_vector(7 downto 0); -- eight LEDs
		sw_in          : in    std_logic_vector(7 downto 0)  -- eight switches
	);
end entity;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;

entity debouncer is
	Generic(wait_cycles : STD_LOGIC_VECTOR(19 downto 0) := x"F423F");
	Port(clk        : in  STD_LOGIC;
		 button     : in  STD_LOGIC;
		 button_deb : out STD_LOGIC);
end debouncer;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;

entity encrypter is
	Port(clk        : in  STD_LOGIC;
		 reset      : in  STD_LOGIC;
		 plaintext  : in  STD_LOGIC_VECTOR(63 downto 0);
		 start      : in  STD_LOGIC;
		 ciphertext : out STD_LOGIC_VECTOR(63 downto 0);
		 done       : out STD_LOGIC);
end encrypter;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;

entity decrypter is
	Port(clk        : in  STD_LOGIC;
		 reset      : in  STD_LOGIC;
		 ciphertext : in  STD_LOGIC_VECTOR(63 downto 0);
		 start      : in  STD_LOGIC;
		 plaintext  : out STD_LOGIC_VECTOR(63 downto 0);
		 done       : out STD_LOGIC);
end decrypter;
