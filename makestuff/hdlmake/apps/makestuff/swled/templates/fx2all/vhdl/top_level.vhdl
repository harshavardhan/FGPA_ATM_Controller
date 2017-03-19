library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
	port(
		-- FX2LP interface ---------------------------------------------------------------------------
		fx2Clk_in      : in    std_logic;                    -- 48MHz clock from FX2LP
		fx2Addr_out    : out   std_logic_vector(1 downto 0); -- select FIFO: "00" for EP2OUT, "10" for EP6IN
		fx2Data_io     : inout std_logic_vector(7 downto 0); -- 8-bit data to/from FX2LP

		-- When EP2OUT selected:
		fx2Read_out    : out   std_logic;                    -- asserted (active-low) when reading from FX2LP
		fx2OE_out      : out   std_logic;                    -- asserted (active-low) to tell FX2LP to drive bus
		fx2GotData_in  : in    std_logic;                    -- asserted (active-high) when FX2LP has data for us

		-- When EP6IN selected:
		fx2Write_out   : out   std_logic;                    -- asserted (active-low) when writing to FX2LP
		fx2GotRoom_in  : in    std_logic;                    -- asserted (active-high) when FX2LP has room for more data from us
		fx2PktEnd_out  : out   std_logic;                    -- asserted (active-low) when a host read needs to be committed early

		-- Onboard peripherals -----------------------------------------------------------------------
		sseg_out       : out   std_logic_vector(7 downto 0); -- seven-segment display cathodes (one for each segment)
		anode_out      : out   std_logic_vector(3 downto 0); -- seven-segment display anodes (one for each digit)
		led_out        : out   std_logic_vector(7 downto 0); -- eight LEDs
		sw_in          : in    std_logic_vector(7 downto 0)  -- eight switches

		-- ATM: ----------------------------------------------------------------------------------------
		next_data_in_button  	: in  STD_LOGIC;
		reset_button 		 	: in  STD_LOGIC;
		start_button 			: in  STD_LOGIC;
		done_button 			: in  STD_LOGIC
	);
end entity;

architecture structural of top_level is
	-- Entities recquired
	component debouncer
		port(clk        : in  STD_LOGIC;
			 button     : in  STD_LOGIC;
			 button_deb : out STD_LOGIC);
	end component;

	component encrypter
		port(clk        : in  STD_LOGIC;
			 reset      : in  STD_LOGIC;
			 plaintext  : in  STD_LOGIC_VECTOR(63 downto 0);
			 start      : in  STD_LOGIC;
			 ciphertext : out STD_LOGIC_VECTOR(63 downto 0);
			 done       : out STD_LOGIC);
	end component;

	component decrypter
		port(clk        : in  STD_LOGIC;
			 reset      : in  STD_LOGIC;
			 ciphertext : in  STD_LOGIC_VECTOR(63 downto 0);
			 start      : in  STD_LOGIC;
			 plaintext  : out STD_LOGIC_VECTOR(63 downto 0);
			 done       : out STD_LOGIC);
	end component;

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

	-- Needed so that the comm_fpga_fx2 module can drive both fx2Read_out and fx2OE_out
	signal fx2Read   : std_logic;

	-- Reset signal so host can delay startup
	signal fx2Reset  : std_logic;

	-- Modification
	signal debounced_next_data  : STD_LOGIC                     := '0';
	--signal debounced_next_data_out_button : STD_LOGIC                     := '0';
	signal start_encrypt : STD_LOGIC                     := '0';
	signal start_decrypt : STD_LOGIC                     := '0';
	signal multi_byte_data_read           : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
	signal ciphertext_out                 : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
	signal plaintext_out                  : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
	signal data_to_be_displayed           : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
	signal encrypted_response			  : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
	signal encryption_over                : STD_LOGIC                     := '1';
	signal decryption_over                : STD_LOGIC                     := '1';
	signal system_state                   : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
	signal debounced_reset                : STD_LOGIC                     := '0';
	signal debounced_start                : STD_LOGIC                     := '0';
	signal debounced_done                 : STD_LOGIC                     := '0';
	signal n2000 	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	signal n1000 	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	signal n500 	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	signal n100 	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
begin
	-- CommFPGA module
	fx2Read_out <= fx2Read;
	fx2OE_out <= fx2Read;
	fx2Addr_out(0) <=  -- So fx2Addr_out(1)='0' selects EP2OUT, fx2Addr_out(1)='1' selects EP6IN
		'0' when fx2Reset = '0'
		else 'Z';

	comm_fpga_fx2 : entity work.comm_fpga_fx2
		port map(
			clk_in         => fx2Clk_in,
			reset_in       => '0',
			reset_out      => fx2Reset,
			
			-- FX2LP interface
			fx2FifoSel_out => fx2Addr_out(1),
			fx2Data_io     => fx2Data_io,
			fx2Read_out    => fx2Read,
			fx2GotData_in  => fx2GotData_in,
			fx2Write_out   => fx2Write_out,
			fx2GotRoom_in  => fx2GotRoom_in,
			fx2PktEnd_out  => fx2PktEnd_out,

			-- DVR interface -> Connects to application module
			chanAddr_out   => chanAddr,
			h2fData_out    => h2fData,
			h2fValid_out   => h2fValid,
			h2fReady_in    => h2fReady,
			f2hData_in     => f2hData,
			f2hValid_in    => f2hValid,
			f2hReady_out   => f2hReady
		);

 	-- ATM requirements
	data_in_debouncer : debouncer
		port map(clk        => clk,
			     button     => next_data_in_button,
			     button_deb => debounced_next_data);

	start_debouncer : debouncer
		port map(clk        => clk,
			     button     => start_button,
			     button_deb => debounced_start);

	done_debouncer: debouncer
		port map(clk        => clk,
			     button     => done_button,
			     button_deb => debounced_done);

	reset_debouncer : debouncer
		port map(clk        => clk,
			     button     => reset,
			     button_deb => debounced_reset);

	encrypt : encrypter
		port map(clk        => clk,
			     reset      => debounced_reset,
			     plaintext  => multi_byte_data_read,
			     start      => start_encrypt,
			     ciphertext => ciphertext_out,
			     done       => encryption_over);

	decrypt : decrypter
		port map(clk        => clk,
			     reset      => debounced_reset,
			     ciphertext => encrypted_response,
			     start      => start_decrypt,
			     plaintext  => plaintext_out,
			     done       => decryption_over);
			

--	steer_enc_or_dec_output_to_display : process(clk, start_encrypt, start_decrypt)
----		variable myline : line;
--	begin
--		if (clk'event AND clk = '1') then
--			if ((start_encrypt = '1') AND (start_decrypt = '0')) then
--				system_state <= '0';
--			elsif ((start_encrypt = '0') AND (start_decrypt = '1')) then
--				system_state <= '1';
--			end if;
--		end if;

--	--		write(myline, string'("system state = "));
--	--		write(myline, system_state);
--	--		writeline(output, myline);
--	end process;

	main_process : process(clk)
		--Input 8 bytes one by one 
		variable input_byte_count  	 	: integer range 0 to 8       := 0;
		variable input_taken_already 	: std_logic := '0';
		variable input_eight_bytes   	: std_logic_vector(63 downto 0) := (others => '0');

	begin
		if debounced_reset = '1' then
			-- Resetting Input variables
			input_byte_count  := 0;
			input_eight_bytes <= (others => '0');
			input_taken_already := '0';

		elsif (clk'event AND clk = '1') then
		
			-- States described below
			-- Ready
			if(system_state = "000") then 
				-- Start button pressed, ready -> taking input
				if (debounced_start = '1') then
					system_state <= "001";
				end if;

			-- Taking Input
			elsif (system_state = "001") then
				--If debounced_next_data is pressed read the 8 bit slide input
				--If it is pressed more than 8 times, nothing happens
				
				-- debounced_next_data == 1 doesnot mean updating registers 
				-- The former value will be 1 for atleast the clk_time_period * no_cycles_in_debouncer
				if debounced_next_data = '1' and input_byte_count < 8 then
					-- If this byte not already taken 
					if input_taken_already = '0' then
						-- Update the registers
						input_eight_bytes(8 * (input_byte_count + 1) - 1 downto 8 * input_byte_count) := sw_in;
						-- Now this byte is taken
						input_taken_already := '1';
						-- Update the byte_count
						input_byte_count := input_byte_count + 1;
						--When pressed for 8th time change the system state to "Encrypt" mode
						if input_byte_count = 8 then
							system_state <= "010"
						end if;
					end if;

				-- debounced_next_data == 0 can only exist right after start 
				-- or after releasing next_data 
				elsif debounced_next_data = '0' then
					-- In all cases input_taken_already can be assigned to zero 
					input_taken_already := '0';
				end if;

			-- Encrypt
			elsif (system_state = "010") then 

			-- Communicating wih backend
			elsif (system_state = "011") then 

			-- Decrypt
			elsif (system_state = "100") then 

			-- Loading cash
			elsif (system_state = "101") then 

			-- Dispensing cash
			elsif (system_state = "110") then 

			-- Invalid user
			elsif (system_state = "111") then 

			end if;
		end if;
	end process;

	--data_to_be_displayed <= ciphertext_out when (system_state = '0') else plaintext_out; -- edit
	--done                 <= encryption_over AND decryption_over;
end architecture;
