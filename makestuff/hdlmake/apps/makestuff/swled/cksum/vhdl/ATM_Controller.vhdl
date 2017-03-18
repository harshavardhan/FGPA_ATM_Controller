library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ATM_Controller is
	generic (N : integer := 10);
	port (
		clk_in 	: in std_logic;
		reset 	: in std_logic
	) ;
end entity ; 

architecture arch of ATM_Controller is

	signal n2000 	: std_logic_vector(7 downto 0) := (others => '0');
	signal n1000 	: std_logic_vector(7 downto 0) := (others => '0');
	signal n500 	: std_logic_vector(7 downto 0) := (others => '0');
	signal n100 	: std_logic_vector(7 downto 0) := (others => '0');
	signal pulse 	: std_logic := '0';
begin

	process( clk_in )
	variable i : integer := 0;
	begin
		if i = N - 1 then
			i := 0;
			pulse := '1';
		else
			i := i + 1;
			pulse := '0';
		end if ;
		
	end process ;



end architecture ;