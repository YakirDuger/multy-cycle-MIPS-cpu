library IEEE;
use ieee.std_logic_1164.all;
package aux_package is
--------------------------------------------------------
	COMPONENT ALU is
	GENERIC (n : INTEGER := 8;
		   k : integer := 3;   -- k=log2(n)
		   m : integer := 4	); -- m=2^(k-1)
	PORT 
	(  
		Y_i,X_i: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
		ALUFN_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
        ena, rst, clk : IN STD_LOGIC ;        --ADDED CLOCK, RESET, ENABLE for PWM signal
		ALUout_o: OUT STD_LOGIC_VECTOR(n-1 downto 0);
		Nflag_o,Cflag_o,Zflag_o,Vflag_o: OUT STD_LOGIC 
	); -- Zflag,Cflag,Nflag,Vflag
	END COMPONENT;
---------------------------------------------------------  
	COMPONENT FA is
		PORT (xi, yi, cin: IN std_logic;
			      s, cout: OUT std_logic);
	END COMPONENT;
---------------------------------------------------------
	COMPONENT AdderSub IS
	GENERIC (n : INTEGER := 8);
    PORT (
        -- Control input
        ALUFN : IN  std_logic_vector(2 DOWNTO 0);  -- Operation select
        
        -- Data inputs
        x     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- First operand
        y     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- Second operand
        
        -- Outputs
        cout  : OUT STD_LOGIC;                      -- Carry output
        q     : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)  -- Result output
    );
	END COMPONENT;
---------------------------------------------------------
	COMPONENT Shifter is
		GENERIC (
			n : integer := 8;  -- n = 8 
			k : integer := 3;  -- log2(n) = 3
			m : integer := 4   -- 2^(k-1) = 4
		);
		PORT (
			x,y           : in  std_logic_vector(n-1 downto 0);   -- x,y input
			ALUFN       : in std_logic_vector(2 downto 0);      -- Shifter selector: "000" = shift left, "001" = shift right.
			res : out std_logic_vector(n-1 downto 0);   -- Shifter output
			cout: out std_logic                        -- Shifter carry output
		);
	END COMPONENT;
---------------------------------------------------------
	COMPONENT Logic IS
		GENERIC (n : INTEGER := 8);
		PORT (x,y: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
			ALUFN: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
			output: OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
	END COMPONENT;

------------Top IO Interface component-------------------------------------
	COMPONENT TopIO_Interface IS
	GENERIC (	HEX_num : integer := 7;
				n : INTEGER := 8
				); 
	PORT (
			clk_ref : in std_logic;        -- Reference clock input (50MHz from board)
			ena, rst  : in std_logic;      -- EXTERNAL reset control
			-- Switch Port
			SW_i : in std_logic_vector(n+1 downto 0);
			-- Keys Ports
			KEY0, KEY1, KEY2, KEY3 : in std_logic;
			-- 7 segment Ports
			HEX0, HEX1, HEX2, HEX3, HEX4, HEX5: out std_logic_vector(HEX_num-1 downto 0);
			-- Leds Port
			LEDs : out std_logic_vector(9 downto 0);
			-- PWM Output Port
			GPIO_9 : out std_logic;        -- Connected to PIN_AH5
			-- PLL Status Output
			PLL_locked : out std_logic     -- PLL lock status indicator
	);
	END COMPONENT;
------------7 Segment component-------------------------------------
	component SevenSegDecoder IS
	GENERIC (	n			: INTEGER := 4;
				SegmentSize	: integer := 7);
	PORT (data		: in STD_LOGIC_VECTOR (n-1 DOWNTO 0);
			seg			: out STD_LOGIC_VECTOR (0 to SegmentSize-1));
	END component;
------------ALU Performance Test Case component-------------------------------------
	component topPureLogicWithoutPLL IS
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
	END component;
--------- PWM unit -------------------------------------------------------
    component PWMunit is
        GENERIC (n : INTEGER := 16);
        PORT (x,y: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
            ALUFN: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            ena, rst, clk : IN STD_LOGIC ;        --ADDED CLOCK, RESET, ENABLE for PWM signal
            PWM_pulse: OUT STD_LOGIC );
    end component ;
------------------------------- PLL ----------------------------------------
	COMPONENT PLL IS
		PORT
		(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC 
		);
	END COMPONENT;
--------------------- Counter Envelope ----------------------------------
	COMPONENT CounterEnvelope is port (
		Clk,En : in std_logic;	
		Qout          : out std_logic_vector (7 downto 0)); 
	end COMPONENT;	
------------------------------- Counter -----------------------------------------
	COMPONENT counter is port (
		clk,enable : in std_logic;	
		q          : out std_logic_vector (7 downto 0)); 
	end COMPONENT;
---------------------------PWM Unit With PLL ---------------------------------------
	COMPONENT PWMunit_with_PLL is
		GENERIC (n : INTEGER := 16);
		PORT (x,y: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
			ALUFN: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
			ena, rst, clk_in : IN STD_LOGIC ;     -- Original clock input (renamed to clk_in)
			PWM_pulse: OUT STD_LOGIC );
	end COMPONENT;
----------------------------------------------------------------------

	component PLL_clk is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
		);
	end component;


end aux_package;

