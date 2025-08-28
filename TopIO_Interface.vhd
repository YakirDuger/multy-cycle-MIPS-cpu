LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------- System Top IO interface with FPGA ---------------
-- Hardware Test Case: Digital System (ALU) Interface IO with FPGA board
-- ALU Inputs (Y,X,ALUFN) are outputs of three registers with KEYX enable and Switches[7:0] as register input
-- KEY0, KEY1, KEY2 - Y, ALUFN, X registers enable respectively
-- KEY3 - System enable/control signal (passed through to modules)
-- Switches[7:0] - Input for registers
-- Y connected to HEX3-HEX2
-- X connected to HEX0-HEX1
-- ALUFN connected to LEDR9-LEDR5
-- ALU Outputs goes to Leds and Hex
-- PWM_pulse output goes to GPIO[9]@PIN_AH5
-- FLAGS are outputs from the top level
-- PLL generates system clock from external reference clock
-------------------------------------
ENTITY TopIO_Interface IS
  GENERIC (	HEX_num : integer := 7;
			n : INTEGER := 8
			); 
  PORT (
		  clk : in std_logic;        -- Reference clock input (50MHz from board)
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
END TopIO_Interface;
------------------------------------------------
ARCHITECTURE struct OF TopIO_Interface IS 
    -- PLL signals
    signal pll_clk : std_logic;         -- System clock from PLL
    signal pll_lock : std_logic;        -- PLL lock signal
    signal pll_reset : std_logic;       -- PLL reset signal
    
    -- ALU Inputs
    signal ALUout, X, Y : std_logic_vector(n-1 downto 0);
    signal Nflag, Cflag, Zflag, Vflag: STD_LOGIC;  -- Internal flags from ALU
    signal ALUFN: std_logic_vector(4 downto 0);
    
    -- PWM signals
    signal PWM_out : std_logic;
    
    -- Reset signal - controlled by external rst OR PLL not locked (KEY3 removed from reset)
    signal reset_signal : std_logic;
    
    -- System enable signal - combines ena with KEY3
    signal system_enable : std_logic;
    
    SIGNAL y_pwm, x_pwm  : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL ALUFN_top : STD_LOGIC_VECTOR(1 downto 0);
    SIGNAL ALUFN_bottom : STD_LOGIC_VECTOR(2 downto 0);
    
BEGIN
    ALUFN_top <= ALUFN(4 downto 3);
    ALUFN_bottom <= ALUFN(2 downto 0);
    
    -- PLL reset logic: reset when external reset is active
    pll_reset <= not KEY3;
    
    -- System reset logic: reset when external reset OR PLL not locked (KEY3 removed)
    reset_signal <= not KEY3 or not pll_lock;

    -- System enable logic: combine external enable with KEY3
    system_enable <= SW_i(8);  -- Both ena and KEY3 must be high for system to be enabled
    
    -- Output PLL lock status
    PLL_locked <= pll_lock;
    
    -------------------PLL Module (using newer Intel FPGA IP)--------------------
    PLLModule: entity work.PLL_clk 
        port map(
            refclk   => clk,      -- Reference clock input
            rst      => pll_reset,    -- PLL reset
            outclk_0 => pll_clk,      -- System clock output
            locked   => pll_lock      -- PLL lock status
        );

    
    -------------------ALU Module -----------------------------
    -- Comment out the original ALU instantiation below for easy reversion
     ALUModule: ALU port map(
        Y_i => Y, 
        X_i => X, 
        ALUFN_i => ALUFN, 
        ena => system_enable,     -- Use combined enable signal
        rst => reset_signal,      -- Use system reset (excludes KEY3)
        clk => pll_clk,           -- Use PLL clock
        ALUout_o => ALUout, 
        Nflag_o => Nflag,         -- Internal signals
        Cflag_o => Cflag, 
        Zflag_o => Zflag, 
        Vflag_o => Vflag
    );
    
    -- Registered wrapper for ALU timing analysis
   -- ALUModule: topPureLogicWithoutPLL port map(
   --     ena => system_enable,
   --     rst => reset_signal,
   --     clk => pll_clk,
   --     X => X,
   --     Y => Y,
   --     ALUFN => ALUFN,
   --     ALUout => ALUout,
   --     Zflag => Zflag,
   --     Cflag => Cflag,
   --     Nflag => Nflag,
   --     Vflag => Vflag
   -- );
    
    -- Filter PWM inputs
    x_pwm <= X when ALUFN_top = "00" else (others => '0');
    y_pwm <= Y when ALUFN_top = "00" else (others => '0'); 

    -------------------PWM Module -----------------------------
    PWMModule: PWMunit 
        generic map(n => n)
        port map(
            x => x_pwm,
            y => y_pwm,
            ALUFN(2 downto 0) => ALUFN_bottom,
            ena => system_enable, -- Use combined enable signal
            rst => reset_signal,  -- Use system reset
            clk => pll_clk,       -- Use PLL clock
            PWM_pulse => PWM_out
        );
    
    -- Connect PWM output to GPIO[9]
    GPIO_9 <= PWM_out;
    LEDs(9 downto 5) <= ALUFN;    -- Show ALUFN on LEDs 9-5 (LED9 will show ALUFN(4))
    
    ---------------------7 Segment Decoder-----------------------------
    -- Display X on 7 segment
    DecoderModuleXHex0: SevenSegDecoder port map(X(3 downto 0) , HEX0);
    DecoderModuleXHex1: SevenSegDecoder port map(X(7 downto 4) , HEX1);
    -- Display Y on 7 segment
    DecoderModuleYHex2: SevenSegDecoder port map(Y(3 downto 0) , HEX2);
    DecoderModuleYHex3: SevenSegDecoder port map(Y(7 downto 4) , HEX3);
    -- Display ALU output on 7 segment
    DecoderModuleOutHex4: SevenSegDecoder port map(ALUout(3 downto 0) , HEX4);
    DecoderModuleOutHex5: SevenSegDecoder port map(ALUout(7 downto 4) , HEX5);
    
    --------------------LEDS Binding-------------------------
    LEDs(0) <= Nflag;
    LEDs(1) <= Cflag;
    LEDs(2) <= Zflag;
    LEDs(3) <= Vflag;
    -- LEDs 4,7,8,9 assigned above, LED9 shows ALUFN(4)
    
    -------------------Keys Binding--------------------------
    -- Register updates using PLL clock
    process(pll_clk, reset_signal) 
    begin
        if reset_signal = '1' then
            -- Reset all registers
            Y <= (others => '0');
            X <= (others => '0');
            ALUFN <= (others => '0');
        elsif rising_edge(pll_clk) then
            -- Register updates on PLL clock edge (only when system is enabled)
            if system_enable = '1' then
                if KEY0 = '0' then
                    Y <= SW_i(n-1 downto 0);
                elsif KEY2 = '0' then
                    ALUFN <= SW_i(4 downto 0);
                elsif KEY1 = '0' then
                    X <= SW_i(n-1 downto 0);	
                end if;
            end if;
        end if;
    end process;
     
END struct;