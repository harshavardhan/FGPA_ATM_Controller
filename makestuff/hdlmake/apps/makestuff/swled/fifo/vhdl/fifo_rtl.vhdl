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

	-- FIFOs implementing the channels
	signal fifoCount               : std_logic_vector(15 downto 0); -- MSB=writeFifo, LSB=readFifo

	-- Write FIFO:
	signal writeFifoInputData      : std_logic_vector(7 downto 0);  -- producer: data
	signal writeFifoInputValid     : std_logic;                     --           valid flag
	signal writeFifoInputReady     : std_logic;                     --           ready flag
	signal writeFifoOutputData     : std_logic_vector(7 downto 0);  -- consumer: data
	signal writeFifoOutputValid    : std_logic;                     --           valid flag
	signal writeFifoOutputReady    : std_logic;                     --           ready flag

	-- Read FIFO:
	signal readFifoInputData       : std_logic_vector(7 downto 0);  -- producer: data
	signal readFifoInputValid      : std_logic;                     --           valid flag
	signal readFifoInputReady      : std_logic;                     --           ready flag
	signal readFifoOutputData      : std_logic_vector(7 downto 0);  -- consumer: data
	signal readFifoOutputValid     : std_logic;                     --           valid flag
	signal readFifoOutputReady     : std_logic;                     --           ready flag

	-- Counter which endlessly puts items into the read FIFO for the host to read
	signal count, count_next       : std_logic_vector(7 downto 0) := (others => '0');

	-- Producer and consumer timers
	signal producerSpeed           : std_logic_vector(3 downto 0);
	signal consumerSpeed           : std_logic_vector(3 downto 0);
begin                                                                     --BEGIN_SNIPPET(fifos)
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				count <= (others => '0');
			else
				count <= count_next;
			end if;
		end if;
	end process;

	-- Wire up write FIFO to channel 0 writes:
	--   flags(2) driven by writeFifoOutputValid
	--   writeFifoOutputReady driven by consumer_timer
	--   LEDs driven by writeFifoOutputData
	writeFifoInputData <=
		h2fData_in;
	writeFifoInputValid <=
		'1' when h2fValid_in = '1' and chanAddr_in = "0000000"
		else '0';
	h2fReady_out <=
		'0' when writeFifoInputReady = '0' and chanAddr_in = "0000000"
		else '1';

	-- Wire up read FIFO to channel 0 reads:
	--   readFifoInputValid driven by producer_timer
	--   flags(0) driven by readFifoInputReady
	count_next <=
		std_logic_vector(unsigned(count) + 1) when readFifoInputValid = '1'
		else count;
	readFifoInputData <=
		count;
	f2hValid_out <=
		'0' when readFifoOutputValid = '0' and chanAddr_in = "0000000"
		else '1';
	readFifoOutputReady <=
		'1' when f2hReady_in = '1' and chanAddr_in = "0000000"
		else '0';
	
	-- Select values to return for each channel when the host is reading
	with chanAddr_in select f2hData_out <=
		readFifoOutputData     when "0000000",  -- get from read FIFO
		fifoCount(15 downto 8) when "0000001",  -- get depth of write FIFO
		fifoCount(7 downto 0)  when "0000010",  -- get depth of read FIFO
		x"00"                  when others;                                   --END_SNIPPET(fifos)
	
	-- Write FIFO: written by host, read by LEDs
	write_fifo : entity work.fifo_wrapper
		port map(
			clk_in          => clk_in,
			depth_out       => fifoCount(15 downto 8),

			-- Production end
			inputData_in    => writeFifoInputData,
			inputValid_in   => writeFifoInputValid,
			inputReady_out  => writeFifoInputReady,

			-- Consumption end
			outputData_out  => writeFifoOutputData,
			outputValid_out => writeFifoOutputValid,
			outputReady_in  => writeFifoOutputReady
		);
	
	-- Read FIFO: written by counter, read by host
	read_fifo : entity work.fifo_wrapper
		port map(
			clk_in          => clk_in,
			depth_out       => fifoCount(7 downto 0),

			-- Production end
			inputData_in    => readFifoInputData,
			inputValid_in   => readFifoInputValid,
			inputReady_out  => readFifoInputReady,

			-- Consumption end
			outputData_out  => readFifoOutputData,
			outputValid_out => readFifoOutputValid,
			outputReady_in  => readFifoOutputReady
		);

	-- Producer timer: how fast stuff is put into the read FIFO
	producerSpeed <= not(sw_in(3 downto 0));
	producer_timer : entity work.timer
		port map(
			clk_in     => clk_in,
			ceiling_in => producerSpeed,
			tick_out   => readFifoInputValid
		);

	-- Consumer timer: how fast stuff is drained from the write FIFO
	consumerSpeed <= not(sw_in(7 downto 4));
	consumer_timer : entity work.timer
		port map(
			clk_in     => clk_in,
			ceiling_in => consumerSpeed,
			tick_out   => writeFifoOutputReady
		);

	-- LEDs and 7-seg display
	led_out <= writeFifoOutputData;
	flags <= '0' & writeFifoOutputValid & '0' & readFifoInputReady;
	seven_seg : entity work.seven_seg
		port map(
			clk_in     => clk_in,
			data_in    => fifoCount,
			dots_in    => flags,
			segs_out   => sseg_out,
			anodes_out => anode_out
		);
end architecture;
