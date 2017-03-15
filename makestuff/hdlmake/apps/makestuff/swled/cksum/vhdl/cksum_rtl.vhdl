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

architecture rtl of swled is
	-- Flags for display on the 7-seg decimal points
	signal flags                   : std_logic_vector(3 downto 0);

	-- Registers implementing the channels
	signal checksum, checksum_next : std_logic_vector(15 downto 0) := (others => '0');
	signal reg0, reg0_next         : std_logic_vector(7 downto 0)  := (others => '0');
begin                                                                     --BEGIN_SNIPPET(registers)
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				reg0 <= (others => '0');
				checksum <= (others => '0');
			else
				reg0 <= reg0_next;
				checksum <= checksum_next;
			end if;
		end if;
	end process;

	-- Drive register inputs for each channel when the host is writing
	reg0_next <=
		h2fData_in when chanAddr_in = "0000000" and h2fValid_in = '1'
		else reg0;
	checksum_next <=
		std_logic_vector(unsigned(checksum) + unsigned(h2fData_in))
			when chanAddr_in = "0000000" and h2fValid_in = '1'
		else h2fData_in & checksum(7 downto 0)
			when chanAddr_in = "0000001" and h2fValid_in = '1'
		else checksum(15 downto 8) & h2fData_in
			when chanAddr_in = "0000010" and h2fValid_in = '1'
		else checksum;
	
	-- Select values to return for each channel when the host is reading
	with chanAddr_in select f2hData_out <=
		sw_in                 when "0000000",
		checksum(15 downto 8) when "0000001",
		checksum(7 downto 0)  when "0000010",
		x"00" when others;

	-- Assert that there's always data for reading, and always room for writing
	f2hValid_out <= '1';
	h2fReady_out <= '1';                                                     --END_SNIPPET(registers)

	-- LEDs and 7-seg display
	led_out <= reg0;
	flags <= "00" & f2hReady_in & reset_in;
	seven_seg : entity work.seven_seg
		port map(
			clk_in     => clk_in,
			data_in    => checksum,
			dots_in    => flags,
			segs_out   => sseg_out,
			anodes_out => anode_out
		);
end architecture;
