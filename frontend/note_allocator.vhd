library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;

entity note_allocator is
	Port(clk        : in  STD_LOGIC;
		 reset      : in  STD_LOGIC;
		 start      : in  STD_LOGIC;
		 -- number of denomination notes available in atm
		 n2000_in	: in std_logic_vector(7 downto 0);
		 n1000_in	: in std_logic_vector(7 downto 0);
		 n500_in	: in std_logic_vector(7 downto 0);
		 n100_in	: in std_logic_vector(7 downto 0);
		 -- amount entered by user (range = 0 - 2^32 - 1)
		 amount_asked : in std_logic_vector(31 downto 0);

		 -- is the allocation possible
		 -- i.e. required amount must be in atm and can be allocated to notes properly
		 allocation_possible : out std_logic;
		 -- allocated of denominations to be dispensed (if possible) 
		 n2000_out	: out std_logic_vector(7 downto 0);
		 n1000_out	: out std_logic_vector(7 downto 0);
		 n500_out	: out std_logic_vector(7 downto 0);
		 n100_out	: out std_logic_vector(7 downto 0);
		 
		 -- receive output 
		 done       : out STD_LOGIC
		 );

end note_allocator;

architecture na_rtl of note_allocator is
	signal system_state        : std_logic_vector(2 downto 0) := (others => '0');
	signal binarysearch_start  : std_logic := '0';

begin
	process(clk, reset) is
		variable amount_asked_int					: integer range 0 to 2147483647 := 0; -- 0 to 2^31 - 1

		-- number of notes of each denomination (one denomination at each system state) that can be dispensed
		variable number_of_notes_dispensable_int	:	integer range 0 to 255 := 0;	-- 0 to 2^8 - 1
		variable left_limit							:	integer range 0 to 255 := 0;	-- 0 to 2^8 - 1
		variable right_limit						:	integer range 0 to 255 := 0;	-- 0 to 2^8 - 1
		variable middle_value						:	integer range 0 to 255 := 0;	-- 0 to 2^8 - 1

	begin
		if reset = '1' then
			-- Reset
			system_state <= (others => '0');
			allocation_possible <= '0';
			done <= '0';
			amount_asked_int := 0;
			number_of_notes_dispensable_int := 0;
			binarysearch_start <= '0';
			
		elsif clk'event and clk = '1' then
			
			-- the allocation starts
			-- at this point all the inputs must be properly fed
			if start = '1' then

				-- initialization
				if system_state = "000" then
					done <= '0';
					-- We are only taking least 31 bits of amount_asked_int
					-- as integer data type can hold only until 2^31 - 1
					-- and amount_asked_int can reach until 2^32 - 1
					amount_asked_int := to_integer(unsigned(amount_asked(30 downto 0)));
					system_state <= "001";
			
				-- allocating 2000 denomination
				elsif system_state = "001" then
					number_of_notes_dispensable_int := to_integer(unsigned(n2000_in));
					if amount_asked_int < 2000 * number_of_notes_dispensable_int then
						--number_of_notes_dispensable_int := amount_asked_int / 2;
						-- number_of_notes_dispensable_int := 1;
						if binarysearch_start = '0' then 
							binarysearch_start <= '1';
							left_limit := 0;
							right_limit := number_of_notes_dispensable_int;
						else
							middle_value := (left_limit + right_limit) / 2;
							if amount_asked_int < 2000 * middle_value then
								right_limit := middle_value;
							else
								if left_limit = middle_value then
									amount_asked_int := amount_asked_int - 2000 * left_limit;
									n2000_out <= std_logic_vector(to_unsigned(left_limit, 8));
									system_state <= "010";
									binarysearch_start <= '0';
								else 
									left_limit := middle_value;
								end if ; 
							end if;
						end if;
					else
						amount_asked_int := amount_asked_int - 2000 * number_of_notes_dispensable_int;
						n2000_out <= std_logic_vector(to_unsigned(number_of_notes_dispensable_int, 8));
						--n2000_out <= n2000_in;
						system_state <= "010";
					end if ;

				-- allocating 1000 denomination
				elsif system_state = "010" then
					number_of_notes_dispensable_int := to_integer(unsigned(n1000_in));
					if amount_asked_int < 1000 * number_of_notes_dispensable_int then
						--number_of_notes_dispensable_int := amount_asked_int / 2;
						-- number_of_notes_dispensable_int := 1;
						if binarysearch_start = '0' then 
							binarysearch_start <= '1';
							left_limit := 0;
							right_limit := number_of_notes_dispensable_int;
						else
							middle_value := (left_limit + right_limit) / 2;
							if amount_asked_int < 1000 * middle_value then
								right_limit := middle_value;
							else
								if left_limit = middle_value then
									amount_asked_int := amount_asked_int - 1000 * left_limit;
									n1000_out <= std_logic_vector(to_unsigned(left_limit, 8));
									system_state <= "011";
									binarysearch_start <= '0';
								else 
									left_limit := middle_value;
								end if ; 
							end if;
						end if;
					else
						amount_asked_int := amount_asked_int - 1000 * number_of_notes_dispensable_int;
						n1000_out <= std_logic_vector(to_unsigned(number_of_notes_dispensable_int, 8));
						--n2000_out <= n2000_in;
						system_state <= "011";
					end if ;

				-- allocating 500 denomination
				elsif system_state = "011" then
					number_of_notes_dispensable_int := to_integer(unsigned(n500_in));
					if amount_asked_int < 500 * number_of_notes_dispensable_int then
						--number_of_notes_dispensable_int := amount_asked_int / 2;
						-- number_of_notes_dispensable_int := 1;
						if binarysearch_start = '0' then 
							binarysearch_start <= '1';
							left_limit := 0;
							right_limit := number_of_notes_dispensable_int;
						else
							middle_value := (left_limit + right_limit) / 2;
							if amount_asked_int < 500 * middle_value then
								right_limit := middle_value;
							else
								if left_limit = middle_value then
									amount_asked_int := amount_asked_int - 500 * left_limit;
									n500_out <= std_logic_vector(to_unsigned(left_limit, 8));
									system_state <= "100";
									binarysearch_start <= '0';
								else 
									left_limit := middle_value;
								end if ; 
							end if;
						end if;
					else
						amount_asked_int := amount_asked_int - 500 * number_of_notes_dispensable_int;
						n500_out <= std_logic_vector(to_unsigned(number_of_notes_dispensable_int, 8));
						--n2000_out <= n2000_in;
						system_state <= "100";
					end if ;

				-- allocating 100 denomination
				elsif system_state = "100" then
					number_of_notes_dispensable_int := to_integer(unsigned(n100_in));
					if amount_asked_int < 100 * number_of_notes_dispensable_int then
						--number_of_notes_dispensable_int := amount_asked_int / 2;
						-- number_of_notes_dispensable_int := 1;
						if binarysearch_start = '0' then 
							binarysearch_start <= '1';
							left_limit := 0;
							right_limit := number_of_notes_dispensable_int;
						else
							middle_value := (left_limit + right_limit) / 2;
							if amount_asked_int < 100 * middle_value then
								right_limit := middle_value;
							else
								if left_limit = middle_value then
									amount_asked_int := amount_asked_int - 100 * left_limit;
									n100_out <= std_logic_vector(to_unsigned(left_limit, 8));
									system_state <= "101";
									binarysearch_start <= '0';
								else 
									left_limit := middle_value;
								end if ; 
							end if;
						end if;
					else
						amount_asked_int := amount_asked_int - 100 * number_of_notes_dispensable_int;
						n100_out <= std_logic_vector(to_unsigned(number_of_notes_dispensable_int, 8));
						--n2000_out <= n2000_in;
						system_state <= "101";
					end if ;

				-- NOTE:
				-- The atm can hold total amount of
				-- 			2000 * 255 + 1000 * 255 + 500 * 255 + 100 * 255 = 918000
				-- 			which is less than 2^31 = 2147483647
				-- If amount_asked(31) = '1' i.e amount_asked_int >= 2^31, which exceeds max amount available in atm
				-- 			so inevitably, allocation_possible must be '0'
				-- Else the allocation process decides the value of allocation_possible
				--
				--
				-- This is done as integer data type cannot hold value more than 2^31 - 1 
				elsif system_state = "101" then
					if amount_asked(31) = '0' and amount_asked_int = 0 then
						allocation_possible <= '1';
					else 
						allocation_possible <= '0';
					end if ;
					done <= '1';
					system_state <= "110";
				end if ;
				
			elsif start = '0' then
				done <= '0';
				allocation_possible <= '0';
				system_state <= (others => '0');
			end if;
		
		end if;

	end process;

end na_rtl;
