
-- VHDL Instantiation Created from source file decrypter.vhd -- 13:13:52 03/25/2017
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT decrypter
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
		ciphertext : IN std_logic_vector(63 downto 0);
		start : IN std_logic;          
		plaintext : OUT std_logic_vector(63 downto 0);
		done : OUT std_logic
		);
	END COMPONENT;

	Inst_decrypter: decrypter PORT MAP(
		clk => ,
		reset => ,
		ciphertext => ,
		start => ,
		plaintext => ,
		done => 
	);


