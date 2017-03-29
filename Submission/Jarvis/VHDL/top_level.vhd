library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
	generic (
		N : integer := 100000000;
		M : integer := 50000000;
		max_no_of_blinks : integer := 8
		);

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
		sw_in          : in    std_logic_vector(7 downto 0); -- eight switches

		-- ATM: ----------------------------------------------------------------------------------------
		next_data_in  	: in  STD_LOGIC;
		reset 		 	: in  STD_LOGIC;
		start 			: in  STD_LOGIC;
		done 			: in  STD_LOGIC
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
			 plaintext  : out STD_LOGIC_VECTOR(31 downto 0);
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
	signal system_state                   : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');

	signal start_encrypt 				  : STD_LOGIC                     := '0';
	signal en_input           			  : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
	signal encryption_over                : STD_LOGIC                     := '1';
	signal en_output 					  : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
	
	signal start_decrypt 				  : STD_LOGIC                     := '0';
	signal de_input			  			  : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
	signal decryption_over                : STD_LOGIC                     := '1';
	signal de_output                  	  : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	
	signal debounced_next_data  		  : STD_LOGIC                     := '0';
	signal debounced_reset                : STD_LOGIC                     := '0';
	signal debounced_start                : STD_LOGIC                     := '0';
	signal debounced_done                 : STD_LOGIC                     := '0';

	signal n2000 	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	signal n1000 	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	signal n500 	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	signal n100 	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	-- 

	signal adequate_cash_in_atm   	  : std_logic := '0';
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
		port map(clk        => fx2Clk_in,
			     button     => next_data_in,
			     button_deb => debounced_next_data);

	start_debouncer : debouncer
		port map(clk        => fx2Clk_in,
			     button     => start,
			     button_deb => debounced_start);

	done_debouncer: debouncer
		port map(clk        => fx2Clk_in,
			     button     => done,
			     button_deb => debounced_done);

	reset_debouncer : debouncer
		port map(clk        => fx2Clk_in,
			     button     => reset,
			     button_deb => debounced_reset);

	encrypt : encrypter
		port map(clk        => fx2Clk_in,
			     reset      => debounced_reset,
			     plaintext  => en_input,
			     start      => start_encrypt,
			     ciphertext => en_output,
			     done       => encryption_over);

	decrypt : decrypter
		port map(clk        => fx2Clk_in,
			     reset      => debounced_reset,
			     ciphertext => de_input,
			     start      => start_decrypt,
			     plaintext  => de_output,
			     done       => decryption_over);

	-- TODO : implement else for all channel i/o
	main_process : process(fx2Clk_in, debounced_reset)
		-- Taking Input (Input 8 bytes one by one) 
		variable input_byte_count  	 	: integer range 0 to 8       := 0;
		variable input_taken_already 	: std_logic := '0';
		variable input_eight_bytes   	: std_logic_vector(63 downto 0) := (others => '0');

		-- Encryption

		-- Communicating wih backend
		variable adequate_cash_in_account 					: std_logic := '0';
		variable user_is_admin 								: std_logic := '0';
		variable response_from_host 						: std_logic_vector(63 downto 0) := (others => '0');
		variable check_for_host_response 					: std_logic_vector(7 downto 0) := (others => '0');

		-- Dispensing Cash
		variable dispensing_done_already 					: std_logic := '0';
		variable no_2000_notes_to_be_dispensed					: integer range 0 to 255 := 0;
		variable no_1000_notes_to_be_dispensed					: integer range 0 to 255 := 0;
		variable no_500_notes_to_be_dispensed						: integer range 0 to 255 := 0;
		variable no_100_notes_to_be_dispensed						: integer range 0 to 255 := 0;
		variable led_4to7_blink_counter						: integer range 0 to 6 	 := 0;

		-- Led Control
		variable time_counter 								: integer range 0 to N := 0;
		variable led_blink_counter							: integer range 0 to max_no_of_blinks := 0;
		variable time_gap 									: std_logic := '0';

	begin
		if debounced_reset = '1' then
			-- Resetting the system state
			system_state <= "000";

			-- Resetting Taking Input variables
			input_byte_count  := 0;
			input_eight_bytes := (others => '0');
			input_taken_already := '0';

			-- Resetting Encryption variables
			start_encrypt <= '0';
			
			-- Resetting Decryption variables
			start_decrypt <= '0';

			-- Communicating wih backend
			adequate_cash_in_atm <= '0';
			adequate_cash_in_account := '0';
			user_is_admin := '0';
			response_from_host := (others => '0');
			check_for_host_response := (others => '0');

			-- Dispensing Cash
			dispensing_done_already := '0';
			no_2000_notes_to_be_dispensed := 0;
			no_1000_notes_to_be_dispensed := 0;
			no_500_notes_to_be_dispensed 	:= 0;
			no_100_notes_to_be_dispensed 	:= 0;
			led_4to7_blink_counter 	:= 0;

			-- Led Control
			led_out <= (others => '0');
			time_counter := 0;
			led_blink_counter := 0;
			time_gap := '0';

		elsif (fx2Clk_in'event AND fx2Clk_in = '1') then
		
			--------------------- States described below ------------------------
			-- Ready
			if(system_state = "000") then
				------------------------------ Initializing variables ----------------------
				-- Resetting Taking Input variables
				input_byte_count  := 0;
				input_eight_bytes := (others => '0');
				input_taken_already := '0';

				-- Resetting Encryption variables
				start_encrypt <= '0';
				
				-- Resetting Decryption variables
				start_decrypt <= '0';

				-- Communicating wih backend
				adequate_cash_in_atm <= '0';
				adequate_cash_in_account := '0';
				user_is_admin := '0';
				response_from_host := (others => '0');
				check_for_host_response := (others => '0');

				-- Dispensing Cash
				dispensing_done_already := '0';
				no_2000_notes_to_be_dispensed := 0;
				no_1000_notes_to_be_dispensed := 0;
				no_500_notes_to_be_dispensed 	:= 0;
				no_100_notes_to_be_dispensed 	:= 0;
				led_4to7_blink_counter 	:= 0;

				-- Led Control
				led_out <= (others => '0');
				led_blink_counter := 0;
				time_gap := '0';

				----------------------------- Initializing Complete ------------------------------------------

				-- Start button pressed, ready -> taking input
				if (debounced_start = '1') then
					system_state <= "001";
				end if;

				---- Still not ready for communication
				--if chanAddr = "0000000" and f2hReady = '1' then
				--	f2hData <= x"00";
				--end if;

				-- Led Control
				led_out <= (others => '0');

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
						input_eight_bytes(63 - 8 * input_byte_count downto 56 - 8 * input_byte_count) := sw_in;
						-- Now this byte is taken
						input_taken_already := '1';
						-- Update the byte_count
						input_byte_count := input_byte_count + 1;
						--When pressed for 8th time change the system state to "Encrypt" mode
						if input_byte_count = 8 then
							-- Puts the eight inputs to encrypter plaintext port
							-- Note that this doesn't start encryption
							en_input <= input_eight_bytes;
							-- Turning Off all leds
							led_out <= (others => '0');
							-- Goes to Next State
							system_state <= "010";
						else
							-- Led Control 
							led_out(3 downto 1) <= std_logic_vector(to_unsigned(input_byte_count, 3));
						end if;
					end if;
				-- debounced_next_data == 0 can only exist right after start 
				-- or after releasing next_data 
				elsif debounced_next_data = '0' then
					-- In all cases input_taken_already can be assigned to zero 
					input_taken_already := '0';
				end if;

				---- Still not ready for communication
				--if chanAddr = "0000000" and f2hReady = '1' then
				--	f2hData <= x"00";
				--end if;

				-- Led Control
				if time_counter > M then
					led_out(0) <= '1';
				else
					led_out(0) <= '0';
				end if;

			-- Encrypt
			elsif (system_state = "010") then

				-- checking Adquate cash in atm
				if input_eight_bytes(31 downto 24) > n2000 
					or input_eight_bytes(23 downto 16) > n1000 
					or input_eight_bytes(15 downto 8) > n500 
					or input_eight_bytes(7 downto 0) > n100 then
					-- Send 0x02 
					adequate_cash_in_atm <= '0';
				else
					-- Send 0x01
					adequate_cash_in_atm <= '1';
				end if;
				
				-- Starting encryption
				start_encrypt <= '1';
			
				-- After encrytion is done
				if encryption_over = '1' then
					system_state <= "011"; -- Goes into next step
				end if;

				---- Still not ready for communication
				--if chanAddr = "0000000" and f2hReady = '1' then
				--	f2hData <= x"00";
				--end if;

				-- Led Control
				if time_counter > M then
					led_out(1 downto 0) <= "11";
				else
					led_out(1 downto 0) <= "00";
				end if;

			-- Communicating wih backend
			elsif (system_state = "011") then

				---- Ready for communication
				--if chanAddr = "0000000" and f2hReady = '1' then
				--	-- Adequate cash in atm
				--	if adequate_cash_in_atm = '1' then 
				--		f2hData <= x"01";
				--	elsif adequate_cash_in_atm = '0' then
				--		f2hData <= x"02";
				--	end if;
				-- This is done outside process
				---- From channel 1 to 8 give out corresponding bytes of input_eight_bytes_encrypted
				--elsif chanAddr = "0000001" and f2hReady = '1' then
				--	f2hData <= en_output(7 downto 0);
				--elsif chanAddr = "0000010" and f2hReady = '1' then
				--	f2hData <= en_output(15 downto 8);
				--elsif chanAddr = "0000011" and f2hReady = '1' then
				--	f2hData <= en_output(23 downto 16);
				--elsif chanAddr = "0000100" and f2hReady = '1' then
				--	f2hData <= en_output(31 downto 24);
				--elsif chanAddr = "0000101" and f2hReady = '1' then
				--	f2hData <= en_output(39 downto 32);
				--elsif chanAddr = "0000110" and f2hReady = '1' then
				--	f2hData <= en_output(47 downto 40);
				--elsif chanAddr = "0000111" and f2hReady = '1' then
				--	f2hData <= en_output(55 downto 48);
				--elsif chanAddr = "0001000" and f2hReady = '1' then
				--	f2hData <= en_output(63 downto 56);
				--end if;

				-- In channel 9 
				if chanAddr = "0001001" and h2fValid = '1' then
					if h2fData = x"00" then 
					-- No communication
					
					elsif h2fData = x"01" then 
					-- Normal User & Adequate Cash in Account
						adequate_cash_in_account := '1';
						user_is_admin := '0';

					elsif h2fData = x"02" then
					-- Normal User & NOT Adequate Cash in Account
						adequate_cash_in_account := '0';
						user_is_admin := '0';

					elsif h2fData = x"03" then
					-- Admin
						user_is_admin := '1';

					elsif h2fData = x"04" then
					-- User Not validated 
						system_state <= "000"; -- Directly go into ready state
					end if;

				end if;

				-- From channels 10 to 17 recieve the data from host
				if chanAddr = "0001010" and h2fValid = '1' then 
					response_from_host(7 downto 0) := h2fData;
					check_for_host_response(0) := '1'; 
				
				elsif chanAddr = "0001011" and h2fValid = '1' then
					response_from_host(15 downto 8) := h2fData;
					check_for_host_response(1) := '1';
				
				elsif chanAddr = "0001100" and h2fValid = '1' then
					response_from_host(23 downto 16) := h2fData;
					check_for_host_response(2) := '1';
				
				elsif chanAddr = "0001101" and h2fValid = '1' then
					response_from_host(31 downto 24) := h2fData;
					check_for_host_response(3) := '1';
				
				elsif chanAddr = "0001110" and h2fValid = '1' then
					response_from_host(39 downto 32) := h2fData;
					check_for_host_response(4) := '1';
				
				elsif chanAddr = "0001111" and h2fValid = '1' then
					response_from_host(47 downto 40) := h2fData;
					check_for_host_response(5) := '1';
				
				elsif chanAddr = "0010000" and h2fValid = '1' then
					response_from_host(55 downto 48) := h2fData;
					check_for_host_response(6) := '1';
				
				elsif chanAddr = "0010001" and h2fValid = '1' then
					response_from_host(63 downto 56) := h2fData;
					check_for_host_response(7) := '1';				
				end if;

				-- If all 8 bytes of response recieved from host
				if check_for_host_response = "11111111" then 
					de_input <= response_from_host; -- Give input to decrypter 
					system_state <= "100"; -- Go to next state 
				end if;

				-- Led Control
				if time_counter > M then
					led_out(1 downto 0) <= "11";
				else
					led_out(1 downto 0) <= "00";
				end if;

			-- Decrypt
			elsif (system_state = "100") then 

				-- Starting decryption
				start_decrypt <= '1';
			
				-- After decrytion is done
				if decryption_over = '1' then 
					-- Turning Off all leds
					led_out <= (others => '0');
					if user_is_admin = '1' then
						system_state <= "101"; -- Goes into Loading cash
					elsif user_is_admin = '0' then
						system_state <= "110"; -- Goes into Dispensing cash
					end if;
				end if;

				-- Led Control
				if time_counter > M then
					led_out(1 downto 0) <= "11";
				else
					led_out(1 downto 0) <= "00";
				end if;

			-- Loading cash
			elsif (system_state = "101") then 
				n2000 <= de_output(31 downto 24);
				n1000 <= de_output(23 downto 16);
				n500  <= de_output(15 downto 8);
				n100  <= de_output(7 downto 0);

				-- Led Control
				if time_counter = N then
					led_blink_counter := led_blink_counter + 1;
				elsif time_counter > M then
					led_out(2 downto 0) <= "111";
				else
					led_out(2 downto 0) <= "000";
				end if;

				-- If the blinking happens for "max_no_of_blinks" then go to next state 
				if led_blink_counter = max_no_of_blinks then
					-- Turning off all the leds
					led_out <= (others => '0');
					-- Going to next state
					system_state <= "111";
				end if;				

			-- Dispensing cash
			elsif (system_state = "110") then

				if adequate_cash_in_account = '1' and adequate_cash_in_atm = '1' then
					if dispensing_done_already = '0' then 
						-- Updating the registers (cash removed)
						n2000 <= std_logic_vector(unsigned(n2000) - unsigned(de_output(31 downto 24)));
						n1000 <= std_logic_vector(unsigned(n1000) - unsigned(de_output(23 downto 16)));
						n500  <= std_logic_vector(unsigned(n500)  - unsigned(de_output(15 downto 8)));
						n100  <= std_logic_vector(unsigned(n100)  - unsigned(de_output(7  downto 0)));
						
						-- No of repective notes to be dispensed
						no_2000_notes_to_be_dispensed := to_integer(unsigned(de_output(31 downto 24)));
						no_1000_notes_to_be_dispensed := to_integer(unsigned(de_output(23 downto 16)));
						no_500_notes_to_be_dispensed 	:= to_integer(unsigned(de_output(15 downto 8)));
						no_100_notes_to_be_dispensed 	:= to_integer(unsigned(de_output(7 downto 0)));

						dispensing_done_already := '1';
					end if;

					-- Dispensing cash in terms of blinks of corresponding leds
					-- 2000 note blinks
					if no_2000_notes_to_be_dispensed > 0 then
						if time_counter = N and time_gap = '0' then
							no_2000_notes_to_be_dispensed := no_2000_notes_to_be_dispensed - 1;
							time_gap                       := '1';
						elsif time_counter = N and time_gap = '1' then
							time_gap                       := '0';
						elsif time_counter > M and time_gap = '0' then
							led_out(7 downto 4) <= "0001";
						else
							led_out(7 downto 4) <= "0000";
						end if;

					-- 1000 note blinks
					elsif no_1000_notes_to_be_dispensed > 0 then
						if time_counter = N and time_gap = '0'then
							no_1000_notes_to_be_dispensed := no_1000_notes_to_be_dispensed - 1;
							time_gap                       := '1';
						elsif time_counter = N and time_gap = '1' then
							time_gap                       := '0';
						elsif time_counter > M and time_gap = '0' then
							led_out(7 downto 4) <= "0010";
						else
							led_out(7 downto 4) <= "0000";
						end if;

					-- 500 note blinks
					elsif no_500_notes_to_be_dispensed > 0 then
						if time_counter = N and time_gap = '0' then
							no_500_notes_to_be_dispensed := no_500_notes_to_be_dispensed - 1;
							time_gap                       := '1';
						elsif time_counter = N and time_gap = '1' then
							time_gap                       := '0';
						elsif time_counter > M and time_gap = '0' then
							led_out(7 downto 4) <= "0100";
						else
							led_out(7 downto 4) <= "0000";
						end if;

					-- 100 note blinks
					elsif no_100_notes_to_be_dispensed > 0 then
						if time_counter = N and time_gap = '0' then
							no_100_notes_to_be_dispensed := no_100_notes_to_be_dispensed - 1;
							time_gap                       := '1';
						elsif time_counter = N and time_gap = '1' then
							time_gap                       := '0';
						elsif time_counter > M and time_gap = '0' then
							led_out(7 downto 4) <= "1000";
						else
							led_out(7 downto 4) <= "0000";
						end if;

					-- All the notes are dispensed (all required led blinks are finished)
					else
						if led_blink_counter = max_no_of_blinks then
							-- Turning off all leds
							led_out <= (others => '0');
							-- Going to dummy state
							system_state <= "111";
						else
							-- Turn off cash dispensing counter leds
							led_out(7 downto 4) <= "0000";
						end if;
					end if;

				elsif adequate_cash_in_account = '0'then
					-- Go to dummy state after sufficient number of blinks
					if led_blink_counter = max_no_of_blinks then
						-- Turning off all leds
						led_out <= (others => '0');
						-- Going to dummy state
						system_state <= "111";
					else
						-- Turn off cash dispensing counter leds
						led_out(7 downto 4) <= "0000";
					end if;

					-- Led Control
					if time_counter = N then
						led_4to7_blink_counter := led_4to7_blink_counter + 1;
					elsif time_counter > M and led_4to7_blink_counter < 3 then
						led_out(7 downto 4) <= "1111";
					else
						led_out(7 downto 4) <= "0000";
					end if;

				elsif adequate_cash_in_account = '1' and adequate_cash_in_atm = '0' then
					-- Go to dummy state after sufficient number of blinks
					if led_blink_counter = max_no_of_blinks then
						-- Turning off all leds
						led_out <= (others => '0');
						-- Going to dummy state
						system_state <= "111";
					else
						-- Turn off cash dispensing counter leds
						led_out(7 downto 4) <= "0000";
					end if;

					-- Led Control
					if time_counter = N then
						led_4to7_blink_counter := led_4to7_blink_counter + 1;
					elsif time_counter > M and led_4to7_blink_counter < 6 then
						led_out(7 downto 4) <= "1111";
					else
						led_out(7 downto 4) <= "0000";
					end if;

				end if;

				-- Led Control
				if led_blink_counter /= max_no_of_blinks then
					if time_counter = N then
						led_blink_counter := led_blink_counter + 1;
					elsif time_counter > M  then
						led_out(3 downto 0) <= "1111";
					else
						led_out(3 downto 0) <= "0000";
					end if;
				else 
					led_out(3 downto 0) <= "0000";
				end if;
			
			-- Dummy state 
			elsif (system_state = "111") then
				-- Waits for done press and goes to Ready state
				if debounced_done = '1' then
					system_state <= "000";
				end if;

			end if;

			-----------------  END OF STATES -----------------

			if time_counter = N then
				time_counter := 0;
			else
				time_counter := time_counter + 1;
			end if;

		end if;
	end process;


	-- I/O
	-- 
	f2hData <= 
			-- No communication code = 0x00
			(others => '0') 
				when (chanAddr = "0000000" and f2hReady = '1' and (system_state = "000" or system_state = "001" or system_state = "010"))
			-- Adequate Cash in atm codes = 0x01 0x02 
			else x"01" when (chanAddr = "0000000" and f2hReady = '1' and system_state = "011" and adequate_cash_in_atm = '1')
			else x"02" when (chanAddr = "0000000" and f2hReady = '1' and system_state = "011" and adequate_cash_in_atm = '0')
			-- If communication is done, in all next states channel0 gives code = 0x"03"
			else x"03" when (chanAddr = "0000000" and f2hReady = '1' and (system_state = "100" or system_state = "101" or system_state = "110" or system_state = "111"))
			-- Channel 1 - 8 
			-- From channel 1 to 8 give out corresponding bytes of input_eight_bytes_encrypted
			else en_output(7 downto 0)   when (chanAddr = "0000001" and f2hReady = '1' and system_state = "011")
			else en_output(15 downto 8)  when (chanAddr = "0000010" and f2hReady = '1' and system_state = "011")
			else en_output(23 downto 16) when (chanAddr = "0000011" and f2hReady = '1' and system_state = "011")
			else en_output(31 downto 24) when (chanAddr = "0000100" and f2hReady = '1' and system_state = "011")
			else en_output(39 downto 32) when (chanAddr = "0000101" and f2hReady = '1' and system_state = "011")
			else en_output(47 downto 40) when (chanAddr = "0000110" and f2hReady = '1' and system_state = "011")
			else en_output(55 downto 48) when (chanAddr = "0000111" and f2hReady = '1' and system_state = "011")
			else en_output(63 downto 56) when (chanAddr = "0001000" and f2hReady = '1' and system_state = "011")
			else (others => '0');


	f2hValid <= '1';
	h2fReady <= '1';

	--data_to_be_displayed <= en_output when (system_state = '0') else de_output; -- edit
	--done                 <= encryption_over AND decryption_over;
end architecture;
