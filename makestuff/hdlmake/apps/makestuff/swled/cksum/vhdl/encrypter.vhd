library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;
use STD.textio.all;                     -- basic I/O
use IEEE.std_logic_textio.all;          -- I/O for logic types


entity encrypter is
	Port(clk        : in  STD_LOGIC;
		 reset      : in  STD_LOGIC;
		 plaintext  : in  STD_LOGIC_VECTOR(63 downto 0);
		 start      : in  STD_LOGIC;
		 ciphertext : out STD_LOGIC_VECTOR(63 downto 0);
		 done       : out STD_LOGIC);
end encrypter;

architecture Behavioral of encrypter is
	signal round        : integer range 32 downto 0 := 0;
	signal system_state : std_logic := '0';
	--signal delta   : std_logic_vector(31 downto 0)  ;
	--signal key     : std_logic_vector(127 downto 0) ;
begin
	process(clk, start, reset, plaintext, round, system_state) is
		variable v0 : std_logic_vector(31 downto 0);
		variable v1 : std_logic_vector(31 downto 0);

		variable sum     : std_logic_vector(31 downto 0)  := (others => '0');
		variable delta   : std_logic_vector(31 downto 0)  := x"9e3779b9";
		variable key     : std_logic_vector(127 downto 0) := x"ff0f745743fd99f775f8c48f2927c18c";
		variable myline  : line;
		variable myline1 : line;

	begin
		if reset = '1' then
			ciphertext <= (others => '0');
			round      <= 0;
			done       <= '1';
			sum := (others => '0');
			system_state <= '0';
			
		elsif clk'event and clk = '1' then
			if start = '1' then
				system_state <= '1';
			end if;
			if system_state = '1' then
				done <= '0';
				delta := x"9e3779b9";
				key := x"ff0f745743fd99f775f8c48f2927c18c";
				if round = 0 then
					v0 := plaintext(31 downto 0);
					v1 := plaintext(63 downto 32);
					--delta <= x"9e3779b9";
					--key <= x"ff0f745743fd99f775f8c48f2927c18c";
				end if;

				if round < 32 then
					--delta <= x"9e3779b9";
					--key <= x"ff0f745743fd99f775f8c48f2927c18c";
					sum := sum + delta;
					v0  := v0 + (((v1(27 downto 0) & "0000") + key(31 downto 0)) xor (v1 + sum) xor (("00000" & v1(31 downto 5)) + key(63 downto 32)));
					v1  := v1 + (((v0(27 downto 0) & "0000") + key(95 downto 64)) xor (v0 + sum) xor (("00000" & v0(31 downto 5)) + key(127 downto 96)));
					report "encryption round " severity note;
					write(myline, round);
					writeline(output, myline);
					round <= round + 1;
				elsif round = 32 then
					ciphertext(63 downto 32) <= v1;
					ciphertext(31 downto 0)  <= v0;
					write(myline1, v1);
					writeline(output, myline1);
					write(myline1, v0);
					writeline(output, myline1);
					done         <= '1';
					system_state <= '0';
				end if;
			elsif start = '0' then
				done <= '0';

			else
				done <= '0';

			end if;
		end if;

	end process;
end Behavioral;