LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
-------------------------------------
ENTITY ALU IS
  GENERIC (n : INTEGER := 8;
		   k : integer := 3;   -- k=log2(n)
		   m : integer := 4	); -- m=2^(k-1)
  PORT 
  (  
	Y_i,X_i: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
		  ALUFN_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
          ena, rst, clk : IN STD_LOGIC ;        --ADDED CLOCK, RESET, ENABLE for PWM signal
		  ALUout_o: OUT STD_LOGIC_VECTOR(n-1 downto 0);
		  Nflag_o, Cflag_o, Zflag_o, Vflag_o: OUT STD_LOGIC
  ); -- Zflag,Cflag,Nflag,Vflag
END ALU;
---------------------------------------------------------------------------
ARCHITECTURE struct OF ALU IS 
	CONSTANT ZERO_VECTOR : std_logic_vector(n-1 downto 0) := (others => '0');
	SIGNAL ALUFN_top : STD_LOGIC_VECTOR(1 downto 0);
	SIGNAL ALUFN_bottom, ALUFN_adder, ALUFN_logic, ALUFN_shifter : STD_LOGIC_VECTOR(2 downto 0);
	SIGNAL X_adder, Y_adder, X_logic, Y_logic, X_shifter, Y_shifter, res_adder, res_logic, res_shifter  : STD_LOGIC_VECTOR(n-1 downto 0);
	SIGNAL cout_adder, cout_shifter, V: STD_LOGIC;
	SIGNAL ALUout_internal : std_logic_vector(n-1 downto 0);

BEGIN
	ALUFN_top <= ALUFN_i(4 downto 3);
	ALUFN_bottom <= ALUFN_i(2 downto 0);

	--------------- INSERTING THE INPUT TO THE CHOSEN MODULE ---------------

	X_adder <= X_i when ALUFN_top = "01" else (others => '0');
	Y_adder <= Y_i when ALUFN_top = "01" else (others => '0');
	ALUFN_adder <= ALUFN_bottom when ALUFN_top = "01" else (others => '0');

	X_logic <= X_i when ALUFN_top = "11" else (others => '0');
	Y_logic <= Y_i when ALUFN_top = "11" else (others => '0');
	ALUFN_logic <= ALUFN_bottom when ALUFN_top = "11" else (others => '0');
	
	X_shifter <= X_i when ALUFN_top = "10" else (others => '0');
	Y_shifter <= Y_i when ALUFN_top = "10" else (others => '0');
	ALUFN_shifter <= ALUFN_bottom when ALUFN_top = "10" else (others => '0');
	
	---------------------- MAPPING THE MODULES ----------------------
	  
	adder : AdderSub
		generic map (n => n)
		PORT MAP (
			ALUFN => ALUFN_adder,
            x => X_adder,
			y => Y_adder,
			cout => cout_adder,           
			q => res_adder);

	logic_unit : Logic
		generic map (n => n)
		PORT MAP (
			x => X_logic,
			y => Y_logic,
			ALUFN => ALUFN_logic,
			output => res_logic);
	
	shifter_unit : Shifter
		generic map (n => n, k=> k, m=>m)
		PORT MAP (
			x => X_shifter,
			y => Y_shifter,
			ALUFN => ALUFN_shifter,
			res => res_shifter,
			cout => cout_shifter
			);
	
	-- PWM unit removed - handled externally
	
	---------------------- OUTPUT ----------------------

	ALUout_internal <= res_adder WHEN (ALUFN_top = "01") ELSE
				res_logic WHEN (ALUFN_top = "11") ELSE
				res_shifter WHEN (ALUFN_top = "10") ELSE
				(others => '0');

	ALUout_o <= ALUout_internal;

	---------------------- NEGATIVE FLAG ----------------------
	Nflag_o <= ALUout_internal(n-1);

	---------------------- CARRY FLAG ----------------------

	Cflag_o <= cout_shifter WHEN (ALUFN_top = "10") ELSE
			cout_adder WHEN (ALUFN_top = "01") ELSE
			'0';
	
	---------------------- ZERO FLAG ----------------------

	Zflag_o <= '1' when ALUout_internal = ZERO_VECTOR else '0';

	---------------------- OVERFLOW FLAG ----------------------
			 
	V <= '1'   when (
    (
      -- Overflow for ADD (ALUFN_bottom = "000")
      ((X_adder(n-1) = '0') and (Y_adder(n-1) = '0') and (ALUout_internal(n-1) = '1') and (ALUFN_bottom = "000")) or
      ((X_adder(n-1) = '1') and (Y_adder(n-1) = '1') and (ALUout_internal(n-1) = '0') and (ALUFN_bottom = "000")) or

      -- Overflow for SUB (ALUFN_bottom = "001")
      ((Y_adder(n-1) = '0') and (X_adder(n-1) = '1') and (ALUout_internal(n-1) = '1') and (ALUFN_bottom = "001")) or
      ((Y_adder(n-1) = '1') and (X_adder(n-1) = '0') and (ALUout_internal(n-1) = '0') and (ALUFN_bottom = "001")) or

      -- Overflow for NEG (ALUFN_bottom = "010"), X = 100...0
      ((X_adder(n-1) = '1') and (X_adder(n-2 downto 0) = (n-2 downto 0 => '0')) and (ALUFN_bottom = "010")) or

      -- Overflow for DEC (ALUFN_bottom = "100"), Y = 100...0
      ((Y_adder(n-1) = '1') and (Y_adder(n-2 downto 0) = (n-2 downto 0 => '0')) and (ALUFN_bottom = "100")) or

      -- Overflow for INC (ALUFN_bottom = "011"), Y = 011...1
      ((Y_adder(n-1) = '0') and (Y_adder(n-2 downto 0) = (n-2 downto 0 => '1')) and (ALUFN_bottom = "011"))
    )
    and (ALUFN_top = "01")) else '0';
 
	Vflag_o <= V;

END struct;