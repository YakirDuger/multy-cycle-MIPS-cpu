LIBRARY ieee;
USE ieee.std_logic_1164.all;
--------------------------------------------------------
ENTITY Logic IS
    GENERIC (n : INTEGER := 8);
    PORT (x,y: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
        ALUFN: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
        output: OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END Logic;
--------------------------------------------------------
ARCHITECTURE dtf of Logic IS
BEGIN
    WITH ALUFN SELECT
    output <= not y WHEN "000",
            y or x WHEN "001",
            y and x WHEN "010",
            y xor x WHEN "011",
            not (y or x) WHEN "100",
            not (y and x) WHEN "101",
            not (y xor x) WHEN "111",
            (OTHERS => '0') WHEN OTHERS;
END dtf;

