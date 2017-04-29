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
					plaintext(31 downto 0) <= v0;
					plaintext(63 downto 32) <= v1;
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
