LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
------------Top ALU Performance Test Case--------------
-- Top for testing the performance, area and functionality of the ALU
-- Because the ALU is asynchronous we need to confine the ALU between two synchronous registers
-- Note: We could use only one process but we divivde it for a better visibility
---
ENTITY topPureLogicWithoutPLL IS
  GENERIC (	
			n : INTEGER := 8
			); 
  PORT (
		  ena, rst, clk : in std_logic; 
		  X, Y : in std_logic_vector(n-1 downto 0);
		  ALUFN: in std_logic_vector(4 downto 0);
		  ALUout : out std_logic_vector(n-1 downto 0);
		  Zflag, Cflag, Nflag, Vflag : out std_logic
  );
END topPureLogicWithoutPLL;
------------------------------------------------
ARCHITECTURE struct OF topPureLogicWithoutPLL IS 

	-- Inputs of the ALU
	signal X_i, Y_i : std_logic_vector(n-1 downto 0);  
	signal ALUFN_i: std_logic_vector(4 downto 0);
	-- Outputs of the ALU
	signal ALUout_o : std_logic_vector(n-1 downto 0);
	signal Zflag_o, Cflag_o, Nflag_o, Vflag_o: std_logic;

BEGIN


	
	
	--- Inputs Register
	process (clk) 
	begin
		if rising_edge(clk) then 
			X_i <= X;
			Y_i <= Y;
			ALUFN_i <= ALUFN;
		end if;
	end process;
	
	-------------------ALU Module -----------------------------
	ALUModule:	ALU	port map(Y_i, X_i, ALUFN_i, ena, rst, clk, ALUout_o, Nflag_o, Cflag_o, Zflag_o, Vflag_o); -- ADDED ena, rst, clk
	-----------------------------------------------------------
	
	--- Outputs Register
	process (clk) 
	begin
		if rising_edge(clk) then 
			ALUout <= ALUout_o;
			Zflag <= Zflag_o;
			Cflag <= Cflag_o;
			Nflag <= Nflag_o;
			Vflag <= Vflag_o;
		end if;
	end process;	
				 
END struct;

