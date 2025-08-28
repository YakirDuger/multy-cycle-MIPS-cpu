LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.aux_package.all;
-------------------------------------
ENTITY SevenSegDecoder IS
  GENERIC (	n			: INTEGER := 4;
			SegmentSize	: integer := 7);
  PORT (data		: in STD_LOGIC_VECTOR (n-1 DOWNTO 0);
		seg   		: out STD_LOGIC_VECTOR (SegmentSize-1 downto 0));
END SevenSegDecoder;
--------------------------------------------------------------
ARCHITECTURE dfl OF SevenSegDecoder IS
BEGIN
	process(data)
	begin
		case data is
			when "0000" => seg <= "1000000"; -- 0
			when "0001" => seg <= "1111001"; -- 1
			when "0010" => seg <= "0100100"; -- 2
			when "0011" => seg <= "0110000"; -- 3
			when "0100" => seg <= "0011001"; -- 4
			when "0101" => seg <= "0010010"; -- 5
			when "0110" => seg <= "0000010"; -- 6
			when "0111" => seg <= "1111000"; -- 7
			when "1000" => seg <= "0000000"; -- 8
			when "1001" => seg <= "0010000"; -- 9
			when "1010" => seg <= "0001000"; -- A
			when "1011" => seg <= "0000011"; -- B
			when "1100" => seg <= "1000110"; -- C
			when "1101" => seg <= "0100001"; -- D
			when "1110" => seg <= "0000110"; -- E
			when "1111" => seg <= "0001110"; -- F
			when others => seg <= "1111111"; -- default
		end case;
	end process;
END dfl;
