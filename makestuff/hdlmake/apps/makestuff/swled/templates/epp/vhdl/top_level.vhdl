--
-- Copyright (C) 2009-2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
	port(
		sysClk_in     : in    std_logic;                     -- clock input (asynchronous with EPP signals)
		
		-- EPP interface -----------------------------------------------------------------------------
		eppData_io    : inout std_logic_vector(7 downto 0);  -- bidirectional 8-bit data bus
		eppAddrStb_in : in    std_logic;                     -- active-low asynchronous address strobe
		eppDataStb_in : in    std_logic;                     -- active-low asynchronous data strobe
		eppWrite_in   : in    std_logic;                     -- read='1'; write='0'
		eppWait_out   : out   std_logic;                     -- active-low asynchronous wait signal

		-- Onboard peripherals -----------------------------------------------------------------------
		sseg_out      : out   std_logic_vector(7 downto 0);  -- seven-segment display cathodes (one for each segment)
		anode_out     : out   std_logic_vector(3 downto 0);  -- seven-segment display anodes (one for each digit)
		led_out       : out   std_logic_vector(7 downto 0);  -- eight LEDs
		sw_in         : in    std_logic_vector(7 downto 0)   -- eight switches
	);
end entity;

architecture structural of top_level is
	-- Channel read/write interface -----------------------------------------------------------------
	signal chanAddr  : std_logic_vector(6 downto 0);  -- the selected channel (0-127)

	-- Host >> FPGA pipe:
	signal h2fData   : std_logic_vector(7 downto 0);  -- data lines used when the host writes to a channel
	signal h2fValid  : std_logic;                     -- '1' means "on the next clock rising edge, please accept the data on h2fData"
	signal h2fReady  : std_logic;                     -- channel logic can drive this low to say "I'm not ready for more data yet"

	-- Host << FPGA pipe:
	signal f2hData   : std_logic_vector(7 downto 0);  -- data lines used when the host reads from a channel
	signal f2hValid  : std_logic;                     -- channel logic can drive this low to say "I don't have data ready for you"
	signal f2hReady  : std_logic;                     -- '1' means "on the next clock rising edge, put your next byte of data on f2hData"
	-- ----------------------------------------------------------------------------------------------
	
	signal eppReset  : std_logic;
begin
	-- CommFPGA module
	comm_fpga_epp : entity work.comm_fpga_epp
		port map(
			clk_in       => sysClk_in,
			reset_in     => '0',
			reset_out    => eppReset,
			
			-- EPP interface
			eppData_io     => eppData_io,
			eppAddrStb_in  => eppAddrStb_in,
			eppDataStb_in  => eppDataStb_in,
			eppWrite_in    => eppWrite_in,
			eppWait_out    => eppWait_out,

			-- DVR interface -> Connects to application module
			chanAddr_out   => chanAddr,
			h2fData_out    => h2fData,
			h2fValid_out   => h2fValid,
			h2fReady_in    => h2fReady,
			f2hData_in     => f2hData,
			f2hValid_in    => f2hValid,
			f2hReady_out   => f2hReady
		);

	-- Switches & LEDs application
	swled_app : entity work.swled
		port map(
			clk_in       => sysClk_in,
			reset_in     => eppReset,
			
			-- DVR interface -> Connects to comm_fpga module
			chanAddr_in  => chanAddr,
			h2fData_in   => h2fData,
			h2fValid_in  => h2fValid,
			h2fReady_out => h2fReady,
			f2hData_out  => f2hData,
			f2hValid_out => f2hValid,
			f2hReady_in  => f2hReady,
			
			-- External interface
			sseg_out     => sseg_out,
			anode_out    => anode_out,
			led_out      => led_out,
			sw_in        => sw_in
		);
end architecture;
