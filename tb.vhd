-- Top-level testbench for system and PWMunit integration
-- Covers ALU operation tests, flag checks, and comprehensive PWM scenarios

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.aux_package.all;

ENTITY top_tb IS
END top_tb;

ARCHITECTURE behavior OF top_tb IS
    -- Component Declarations
    COMPONENT topPureLogicWithoutPLL
        GENERIC (n : INTEGER := 8);
        PORT (
            ena, rst, clk : in std_logic;
            X, Y : in std_logic_vector(n-1 downto 0);
            ALUFN: in std_logic_vector(4 downto 0);
            ALUout : out std_logic_vector(n-1 downto 0);
            Zflag, Cflag, Nflag, Vflag : out std_logic
        );
    END COMPONENT;

    COMPONENT PWMunit
        GENERIC (n: integer := 8);
        PORT (
            X, Y    : IN std_logic_vector(n-1 downto 0);
            ALUFN   : IN std_logic_vector(4 downto 0);
            ena, rst, clk : IN std_logic;
            PWM_pulse : OUT std_logic
        );
    END COMPONENT;

    -- Inputs/Outputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal ena : std_logic := '0';
    signal X : std_logic_vector(7 downto 0) := (others => '0');
    signal Y : std_logic_vector(7 downto 0) := (others => '0');
    signal ALUFN : std_logic_vector(4 downto 0) := "01000"; -- Y+X as a safe default

    signal ALUout : std_logic_vector(7 downto 0);
    signal Zflag : std_logic;
    signal Cflag : std_logic;
    signal Nflag : std_logic;
    signal Vflag : std_logic;
    signal PWM_pulse : std_logic;

    constant clk_period : time := 10 ns;

BEGIN
    -- UUT instantiations
    uut: topPureLogicWithoutPLL PORT MAP (
        clk => clk, rst => rst, ena => ena, X => X, Y => Y, ALUFN => ALUFN,
        ALUout => ALUout, Zflag => Zflag, Cflag => Cflag, Nflag => Nflag, Vflag => Vflag
    );
    pwm_inst: PWMunit
        GENERIC MAP (n => 8)
        PORT MAP (
            X => X, Y => Y, ALUFN => ALUFN, ena => ena, rst => rst, clk => clk, PWM_pulse => PWM_pulse
        );

    -- Clock process
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Main stimulus process
    stim_proc: process
    begin
        -- Initial state
        rst <= '1';
        ena <= '0';
        X <= (others => '0');
        Y <= (others => '0');
        ALUFN <= "01000"; -- Y+X as a safe default
        wait for 50 ns;

        rst <= '0';
        ena <= '1';
        wait for 50 ns;

        -- Print test start message
        report "Starting Top Testbench with PWMunit integration" severity note;

        -- ALU and Flag Tests
        -- Test 1: Reset functionality
        report "Test 1: Reset functionality" severity note;
        rst <= '1';
        ena <= '1';
        X <= x"40";  -- 64 decimal
        Y <= x"80";  -- 128 decimal
        ALUFN <= "00000";
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        -- Test Zflag: Addition resulting in zero
        report "Test Zflag: Addition resulting in zero" severity note;
        X <= x"FF";  -- 255
        Y <= x"01";  -- 1
        ALUFN <= "01000"; -- Y + X
        wait for 20 ns;
        assert ALUout = x"00" report "Zflag test: Output not zero" severity error;
        assert Zflag = '1' report "Zflag test: Zflag not set for zero result" severity error;

        -- Test Cflag: Addition with carry out
        report "Test Cflag: Addition with carry out" severity note;
        X <= x"FF";  -- 255
        Y <= x"01";  -- 1
        ALUFN <= "01000"; -- Y + X
        wait for 20 ns;
        assert Cflag = '1' report "Cflag test: Cflag not set for carry out" severity error;

        -- Test Nflag: Subtraction resulting in negative
        report "Test Nflag: Subtraction resulting in negative" severity note;
        X <= x"05";  -- 5
        Y <= x"03";  -- 3
        ALUFN <= "01001"; -- Y - X
        wait for 20 ns;
        assert ALUout = x"FE" report "Nflag test: Output not negative (-2)" severity error;
        assert Nflag = '1' report "Nflag test: Nflag not set for negative result" severity error;

        -- Test Vflag: Addition with signed overflow
        report "Test Vflag: Addition with signed overflow" severity note;
        X <= x"7F";  -- 127         
        Y <= x"01";  -- 1
        ALUFN <= "01000"; -- Y + X
        wait for 20 ns;
        assert ALUout = x"80" report "Vflag test: Output not -128 (overflow)" severity error;
        assert Vflag = '1' report "Vflag test: Vflag not set for signed overflow" severity error;

        -- Additional ALU operation tests
        -- Arithmetic
        X <= x"05"; Y <= x"03"; ALUFN <= "01000"; wait for 20 ns; -- Y + X = 8
        X <= x"05"; Y <= x"03"; ALUFN <= "01001"; wait for 20 ns; -- Y - X = -2
        X <= x"05"; Y <= x"00"; ALUFN <= "01010"; wait for 20 ns; -- neg(X)
        X <= x"00"; Y <= x"07"; ALUFN <= "01011"; wait for 20 ns; -- Y + 1
        X <= x"00"; Y <= x"07"; ALUFN <= "01100"; wait for 20 ns; -- Y - 1
        X <= x"00"; Y <= x"CC"; ALUFN <= "01101"; wait for 20 ns; -- swap(Y)
        -- Shift
        X <= x"01"; Y <= x"80"; ALUFN <= "10000"; wait for 20 ns; -- SHL
        X <= x"01"; Y <= x"80"; ALUFN <= "10001"; wait for 20 ns; -- SHR
        -- Boolean
        X <= x"CC"; Y <= x"AA"; ALUFN <= "11000"; wait for 20 ns; -- not(Y)
        X <= x"CC"; Y <= x"AA"; ALUFN <= "11001"; wait for 20 ns; -- Y or X
        X <= x"CC"; Y <= x"AA"; ALUFN <= "11010"; wait for 20 ns; -- Y and X
        X <= x"CC"; Y <= x"AA"; ALUFN <= "11011"; wait for 20 ns; -- Y xor X
        X <= x"CC"; Y <= x"AA"; ALUFN <= "11100"; wait for 20 ns; -- Y nor X
        X <= x"CC"; Y <= x"AA"; ALUFN <= "11101"; wait for 20 ns; -- Y nand X
        X <= x"CC"; Y <= x"AA"; ALUFN <= "11110"; wait for 20 ns; -- Y xnor X

        -- PWMunit tests
        -- Test 2: PWM Mode 000 (Set/Reset mode) - 50% duty cycle
        report "Test 2: PWM Mode 000 - Set/Reset mode, 50% duty cycle" severity note;
        ena <= '1';
        X <= x"40";    -- Duty cycle = 64
        Y <= x"80";    -- Period = 128
        ALUFN <= "00000";
        wait for 5000 ns;

        -- Test 3: PWM Mode 000 - 25% duty cycle
        report "Test 3: PWM Mode 000 - Set/Reset mode, 25% duty cycle" severity note;
        X <= x"20";    -- Duty cycle = 32 (25% of 128)
        Y <= x"80";    -- Period = 128
        ALUFN <= "00000";
        wait for 5000 ns;

        -- Test 4: PWM Mode 000 - 75% duty cycle
        report "Test 4: PWM Mode 000 - Set/Reset mode, 75% duty cycle" severity note;
        X <= x"60";    -- Duty cycle = 96 (75% of 128)
        Y <= x"80";    -- Period = 128
        ALUFN <= "00000";
        wait for 5000 ns;

        -- Test 5: PWM Mode 001 (Reset/Set mode) - 50% duty cycle
        report "Test 5: PWM Mode 001 - Reset/Set mode, 50% duty cycle" severity note;
        X <= x"40";    -- Duty cycle = 64
        Y <= x"80";    -- Period = 128
        ALUFN <= "00001";
        wait for 5000 ns;

        -- Test 6: PWM Mode 010 (Toggle mode)
        report "Test 6: PWM Mode 010 - Toggle mode" severity note;
        X <= x"40";    -- Duty cycle = 64
        Y <= x"80";    -- Period = 128
        ALUFN <= "00010";
        wait for 10000 ns;

        -- Test 7: Small period test
        report "Test 7: Small period test" severity note;
        X <= x"08";    -- Duty cycle = 8
        Y <= x"10";    -- Period = 16
        ALUFN <= "00000";
        wait for 2000 ns;

        -- Test 8: Maximum period test
        report "Test 8: Maximum period test" severity note;
        X <= x"80";    -- Duty cycle = 128
        Y <= x"FF";    -- Period = 255
        ALUFN <= "00000";
        wait for 10000 ns;

        -- Test 9: Disable enable signal
        report "Test 9: Enable signal disabled" severity note;
        ena <= '0';
        X <= x"40";
        Y <= x"80";
        ALUFN <= "00000";
        wait for 3000 ns;

        -- Test 10: Re-enable
        report "Test 10: Re-enable PWM" severity note;
        ena <= '1';
        wait for 3000 ns;

        -- Test 11: Invalid ALUFN mode
        report "Test 11: Invalid ALUFN mode (111)" severity note;
        ALUFN <= "11111";
        wait for 3000 ns;

        -- Test 12: Edge case - x >= y
        report "Test 12: Edge case - x >= y" severity note;
        X <= x"80";    -- Duty cycle = 128
        Y <= x"40";    -- Period = 64 (x > y)
        ALUFN <= "00000";
        wait for 3000 ns;

        -- Test 13: Zero duty cycle
        report "Test 13: Zero duty cycle" severity note;
        X <= x"00";    -- Duty cycle = 0
        Y <= x"80";    -- Period = 128
        ALUFN <= "00000";
        wait for 3000 ns;

        -- Test 14: Zero period
        report "Test 14: Zero period" severity note;
        X <= x"40";    -- Duty cycle = 64
        Y <= x"00";    -- Period = 0
        ALUFN <= "00000";
        wait for 1000 ns;

        -- End of tests
        report "All tests completed successfully!" severity note;
        wait;
    end process;

END behavior; 