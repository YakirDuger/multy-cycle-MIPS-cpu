LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;

Entity PWMunit_with_PLL is
    GENERIC (n : INTEGER := 16);
    PORT (x,y: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
        ALUFN: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
        ena, rst, clk_in : IN STD_LOGIC ;     -- Original clock input (renamed to clk_in)
        PWM_pulse: OUT STD_LOGIC );
end PWMunit_with_PLL;

ARCHITECTURE struct of PWMunit_with_PLL IS
    -- PWM_unit component declaration
    COMPONENT PWMunit is
        GENERIC (n : INTEGER := 16);
        PORT (x,y: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
            ALUFN: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            ena, rst, clk : IN STD_LOGIC ;
            PWM_pulse: OUT STD_LOGIC );
    end COMPONENT;
    
    -- PLL component declaration
    COMPONENT PLL PORT(
        areset    : IN STD_LOGIC  := '0';
        inclk0    : IN STD_LOGIC  := '0';
        c0        : OUT STD_LOGIC ;
        locked    : OUT STD_LOGIC 
    );
    END COMPONENT;
    
    -- Internal signals
    SIGNAL pll_clock : STD_LOGIC;
    SIGNAL pll_locked : STD_LOGIC;
    SIGNAL pwm_enable : STD_LOGIC;
    
BEGIN
    -- Only enable the PWM when PLL is locked
    pwm_enable <= ena AND pll_locked;
    
    -- Instantiate the PLL
    pll_inst: PLL PORT MAP(
        areset => rst,
        inclk0 => clk_in,
        c0 => pll_clock,
        locked => pll_locked
    );
    
    -- Instantiate the PWM_unit with PLL clock
    pwm_inst: PWMunit 
        GENERIC MAP(n => n)
        PORT MAP(
            x => x,
            y => y,
            ALUFN => ALUFN,
            ena => pwm_enable,
            rst => rst,
            clk => pll_clock,
            PWM_pulse => PWM_pulse
        );
        
END struct;