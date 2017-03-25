library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--architecture rtl of mod_swled is
--	-- Flags for display on the 7-seg decimal points
--	signal flags                   : std_logic_vector(3 downto 0);

--	-- Registers implementing the channels
--	signal checksum, checksum_next : std_logic_vector(15 downto 0) := (others => '0');
--	signal reg0, reg0_next         : std_logic_vector(7 downto 0)  := (others => '0');
--begin                                                                     --BEGIN_SNIPPET(registers)
--	-- Infer registers
--	process(clk_in)
--	begin
--		if ( rising_edge(clk_in) ) then
--			if ( reset_in = '1' ) then
--				reg0 <= (others => '0');
--				checksum <= (others => '0');
--			else
--				reg0 <= reg0_next;
--				checksum <= checksum_next;
--			end if;
--		end if;
--	end process;

--	-- Drive register inputs for each channel when the host is writing
--	reg0_next <=
--		h2fData_in when chanAddr_in = "0000000" and h2fValid_in = '1'
--		else reg0;
--	checksum_next <=
--		std_logic_vector(unsigned(checksum) + unsigned(h2fData_in))
--			when chanAddr_in = "0000000" and h2fValid_in = '1'
--		else h2fData_in & checksum(7 downto 0)
--			when chanAddr_in = "0000001" and h2fValid_in = '1'
--		else checksum(15 downto 8) & h2fData_in
--			when chanAddr_in = "0000010" and h2fValid_in = '1'
--		else checksum;
	
--	-- Select values to return for each channel when the host is reading
--	with chanAddr_in select f2hData_out <=
--		sw_in                 when "0000000",
--		checksum(15 downto 8) when "0000001",
--		checksum(7 downto 0)  when "0000010",
--		x"00" when others;

--	-- Assert that there's always data for reading, and always room for writing
--	f2hValid_out <= '1';
--	h2fReady_out <= '1';                                                     --END_SNIPPET(registers)

--	-- LEDs and 7-seg display
--	led_out <= reg0;
--	flags <= "00" & f2hReady_in & reset_in;
--	seven_seg : entity work.seven_seg
--		port map(
--			clk_in     => clk_in,
--			data_in    => checksum,
--			dots_in    => flags,
--			segs_out   => sseg_out,
--			anodes_out => anode_out
--		);
--end architecture;

architecture debouncer_rtl of debouncer is
begin
	process(clk, button)
		variable oldbutton : STD_LOGIC := '1';
		variable count     : STD_LOGIC_VECTOR(19 downto 0);

	begin
		if (clk'event AND clk = '1') then
			if (oldbutton /= button) then
				count     := (others => '0'); -- reset counter
				oldbutton := button;    -- save current value of button
			else
				count := count + '1';   -- increment counter
				if ((count = wait_cycles) AND (oldbutton = button)) then
					button_deb <= oldbutton; -- button had persistent value
				end if;
			end if;
		end if;
	end process;
end debouncer_rtl;

architecture en_rtl of encrypter is
	signal round        : integer range 0 to 33 := 0;
begin
	process(clk, start, reset, plaintext, round) is
		variable v0 : std_logic_vector(31 downto 0);
		variable v1 : std_logic_vector(31 downto 0);
		variable sum     : std_logic_vector(31 downto 0)  := (others => '0');
		variable delta   : std_logic_vector(31 downto 0)  := x"9e3779b9";
		variable key     : std_logic_vector(127 downto 0) := x"ff0f745743fd99f775f8c48f2927c18c";

	begin
		if reset = '1' then
			round <= 0;
			sum := (others => '0');
			ciphertext <= (others => '0');
			done <= '0';
			
		elsif clk'event and clk = '1' then
			
			if start = '1' then

				delta := x"9e3779b9";
				key := x"ff0f745743fd99f775f8c48f2927c18c";

				if round = 0 then
					done <= '0';
					sum := (others => '0');
					v0 := plaintext(31 downto 0);
					v1 := plaintext(63 downto 32);
				end if;

				if round < 32 then
					sum := sum + delta;
					v0  := v0 + (((v1(27 downto 0) & "0000") + key(31 downto 0)) xor (v1 + sum) xor (("00000" & v1(31 downto 5)) + key(63 downto 32)));
					v1  := v1 + (((v0(27 downto 0) & "0000") + key(95 downto 64)) xor (v0 + sum) xor (("00000" & v0(31 downto 5)) + key(127 downto 96)));
					round <= round + 1;
				elsif round = 32 then
					ciphertext(63 downto 32) <= v1;
					ciphertext(31 downto 0)  <= v0;
					round <= 33;
					done <= '1';
				end if;
			
			elsif start = '0' then
				done <= '0';
				round <= 0;

			end if;
		end if;

	end process;
end en_rtl;


architecture de_rtl of decrypter is
	signal round : integer range 0 to 33 := 0;
begin
	process(clk, start, reset, ciphertext, round) is
		variable v0           : std_logic_vector(31 downto 0);
		variable v1           : std_logic_vector(31 downto 0);
		variable sum          : std_logic_vector(31 downto 0)  := x"C6EF3720";
		variable delta        : std_logic_vector(31 downto 0)  := x"9e3779b9";
		variable key          : std_logic_vector(127 downto 0) := x"ff0f745743fd99f775f8c48f2927c18c";

	begin
		if reset = '1' then
			round     <= 0;
			sum := x"C6EF3720";
			plaintext <= (others => '0');
			done      <= '0';
		
		elsif clk'event and clk = '1' then
			
			if start = '1' then

				key := x"ff0f745743fd99f775f8c48f2927c18c";
				delta := x"9e3779b9" ;
				
				if round = 0 then
					done <= '0';
					sum := x"C6EF3720";
					v0 := ciphertext(31 downto 0);
					v1 := ciphertext(63 downto 32);
				end if;
				
				if round < 32 then
					v1  := v1 - (((v0(27 downto 0) & "0000") + key(95 downto 64)) xor (v0 + sum) xor (("00000" & v0(31 downto 5)) + key(127 downto 96)));
					v0  := v0 - (((v1(27 downto 0) & "0000") + key(31 downto 0)) xor (v1 + sum) xor (("00000" & v1(31 downto 5)) + key(63 downto 32)));
					sum := sum - delta;
					round <= round + 1;
				elsif round = 32 then
					plaintext <= v0;
					round <= 33;
					done <= '1';
				end if;

			elsif start = '0' then
				done <= '0';
				round <= 0;
			end if;

		end if;
	end process;
end de_rtl;
