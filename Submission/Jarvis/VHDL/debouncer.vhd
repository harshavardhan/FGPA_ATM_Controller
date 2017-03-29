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
