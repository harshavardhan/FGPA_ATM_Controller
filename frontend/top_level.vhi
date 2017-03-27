
-- VHDL Instantiation Created from source file top_level.vhd -- 13:20:46 03/25/2017
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT top_level
	PORT(
		fx2Clk_in : IN std_logic;
		fx2GotData_in : IN std_logic;
		fx2GotRoom_in : IN std_logic;
		sw_in : IN std_logic_vector(7 downto 0);
		next_data_in_button : IN std_logic;
		reset_button : IN std_logic;
		start_button : IN std_logic;
		done_button : IN std_logic;    
		fx2Data_io : INOUT std_logic_vector(7 downto 0);      
		fx2Addr_out : OUT std_logic_vector(1 downto 0);
		fx2Read_out : OUT std_logic;
		fx2OE_out : OUT std_logic;
		fx2Write_out : OUT std_logic;
		fx2PktEnd_out : OUT std_logic;
		sseg_out : OUT std_logic_vector(7 downto 0);
		anode_out : OUT std_logic_vector(3 downto 0);
		led_out : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

	Inst_top_level: top_level PORT MAP(
		fx2Clk_in => ,
		fx2Addr_out => ,
		fx2Data_io => ,
		fx2Read_out => ,
		fx2OE_out => ,
		fx2GotData_in => ,
		fx2Write_out => ,
		fx2GotRoom_in => ,
		fx2PktEnd_out => ,
		sseg_out => ,
		anode_out => ,
		led_out => ,
		sw_in => ,
		next_data_in_button => ,
		reset_button => ,
		start_button => ,
		done_button => 
	);


