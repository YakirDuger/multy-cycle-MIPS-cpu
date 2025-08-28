--------------------------------------------------------
-- Ripple Adder Component
--------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Ripple_adder IS
    GENERIC (
        n : INTEGER := 8  -- Bit width parameter
    );
    PORT (
        -- Control inputs
        cin  : IN STD_LOGIC;                      -- Carry input
        cond : IN STD_LOGIC;                      -- Condition (for subtraction)
        
        -- Data inputs
        x    : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- First operand
        y    : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- Second operand
        
        -- Outputs
        cout : OUT STD_LOGIC;                     -- Carry output
        s    : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0) -- Sum output
    );
END Ripple_adder;

ARCHITECTURE dfl OF Ripple_adder IS
    -- Full Adder component declaration
    COMPONENT FA IS
        PORT (
            xi, yi, cin : IN  std_logic;  -- Inputs
            s, cout     : OUT std_logic   -- Outputs
        );
    END COMPONENT;
    
    -- Internal signals
    SIGNAL reg   : std_logic_vector(n-1 DOWNTO 0); -- Internal carry chain
    SIGNAL x_tag : STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- Modified input (for subtraction)
    
BEGIN
    -- Generate modified input based on condition (for subtraction)
    initial: FOR i IN 0 TO n-1 GENERATE
        x_tag(i) <= (x(i) XOR cond);
    END GENERATE;
    
    -- First full adder in the chain
    first: FA PORT MAP (
        xi   => x_tag(0),
        yi   => y(0),
        cin  => cin,
        s    => s(0),
        cout => reg(0)
    );
    
    -- Generate the rest of the full adders in the chain
    rest: FOR i IN 1 TO n-1 GENERATE
        chain: FA PORT MAP (
            xi   => x_tag(i),
            yi   => y(i),
            cin  => reg(i-1),
            s    => s(i),
            cout => reg(i)
        );
    END GENERATE;
    
    -- Set the final carry output
    cout <= reg(n-1);
END dfl;

--------------------------------------------------------
-- Adder/Subtractor Component
--------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY AdderSub IS
    GENERIC (
        n : INTEGER := 8;  -- Bit width parameter
        k : INTEGER := 4
    );
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
END AdderSub;

ARCHITECTURE Adder_inside OF AdderSub IS
    -- Component declarations
    COMPONENT FA IS
        PORT (
            xi, yi, cin : IN  STD_LOGIC;  -- Inputs
            s, cout     : OUT STD_LOGIC   -- Outputs
        );
    END COMPONENT;
    
    COMPONENT Ripple_adder IS
        GENERIC (
            n : INTEGER := 16  -- Bit width parameter
        );
        PORT (
            cin, cond   : IN  STD_LOGIC;                     -- Control inputs
            x, y        : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- Data inputs
            cout        : OUT STD_LOGIC;                      -- Carry output
            s           : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)  -- Sum output
        );
    END COMPONENT;
    
    -- Type and signal declarations
    TYPE mem1 IS ARRAY (0 TO 6) OF STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL res         : mem1;                      -- Results matrix
    SIGNAL Carry_Out_Vec   : STD_LOGIC_VECTOR(4 DOWNTO 0); -- Carry output vector
    SIGNAL zeros           : std_logic_vector(n-1 DOWNTO 0); -- Zero vector
    SIGNAL One             : STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- "1" vector
    SIGNAL vec_A, vec_B    : STD_LOGIC_VECTOR(k-1 DOWNTO 0); -- for swap

    
BEGIN
    -- Initialize constant vectors
    zeros <= (OTHERS => '0');
    one <= (0 => '1', OTHERS => '0');
    
    -- Generate different adder operations
    g0: Ripple_adder  -- x + y (Addition)
        GENERIC MAP (n) 
        PORT MAP (
            x    => x, 
            y    => y, 
            cin  => '0', 
            cond => '0', 
            cout => Carry_Out_Vec(0), 
            s    => res(0)
        );
        
    g1: Ripple_adder  -- y - x (Subtraction)
        GENERIC MAP (n) 
        PORT MAP (
            x    => x, 
            y    => y, 
            cin  => '1', 
            cond => '1', 
            cout => Carry_Out_Vec(1), 
            s    => res(1)
        );
        
    g2: Ripple_adder  -- -x (Negate)
        GENERIC MAP (n) 
        PORT MAP (
            x    => x, 
            y    => zeros, 
            cin  => '1', 
            cond => '1', 
            cout => Carry_Out_Vec(2), 
            s    => res(2)
        );
        
    g3: Ripple_adder  -- y + 1 (Increment y)
        GENERIC MAP (n) 
        PORT MAP (
            x    => one, 
            y    => y, 
            cin  => '0', 
            cond => '0', 
            cout => Carry_Out_Vec(3), 
            s    => res(3)
        );
        
    g4: Ripple_adder  -- y - 1 (Decrement y)
        GENERIC MAP (n) 
        PORT MAP (
            x    => one, 
            y    => y, 
            cin  => '1', 
            cond => '1', 
            cout => Carry_Out_Vec(4), 
            s    => res(4)
        );
        
    -- Set zeros for unused operation
    res(5) <= zeros;
    
    ----------------- for swap --------------
    vec_A   <= y(n-1 downto k);
    vec_B   <= y(k-1 downto 0);
    res(6)  <= vec_B & vec_A;

    -- Output multiplexers based on operation select
    WITH ALUFN SELECT
        q <= res(0) WHEN "000",  -- Addition
             res(1) WHEN "001",  -- Subtraction
             res(2) WHEN "010",  -- Negate
             res(3) WHEN "011",  -- Increment
             res(4) WHEN "100",  -- Decrement
             res(6) WHEN "101",  -- swap
             res(5) WHEN OTHERS; -- Zero (default)
             
    WITH ALUFN SELECT
        cout <= Carry_Out_Vec(0) WHEN "000",  -- Addition carry
               Carry_Out_Vec(1) WHEN "001",  -- Subtraction carry
               Carry_Out_Vec(2) WHEN "010",  -- Negate carry
               Carry_Out_Vec(3) WHEN "011",  -- Increment carry
               Carry_Out_Vec(4) WHEN "100",  -- Decrement carry
               '0' WHEN OTHERS;              -- No carry (default)
               
END Adder_inside;