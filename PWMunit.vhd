LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;

entity PWMunit is 
	generic (n: integer:=16);
	port ( X, Y : in std_logic_vector (n-1 downto 0);
			ALUFN : in std_logic_vector (4 downto 0);
			ena,rst,clk : in std_logic;
			PWM_pulse : out std_logic);
end PWMunit;

architecture Inside of PWMunit is

	signal Timer_vec : std_logic_vector (n-1 downto 0);
	signal PWM_mode  : std_logic_vector (1 downto 0);
	signal zeros     : std_logic_vector (n-1 downto 0):= (others => '0');
	signal set_toggle : std_logic := '0'; 
	 
begin

	Timer_vec_update : process(clk, rst)
	begin
		if (rst='1') then
			Timer_vec <= zeros;
		elsif (clk' EVENT and clk = '1' and ena = '1' and Timer_vec >= Y) then
			Timer_vec <= zeros;
		elsif (clk'EVENT and clk='1' and ena = '1') then
			Timer_vec <= Timer_vec + '1' ;
		end if;
	end process;

	pwm_config: process(clk, rst)
	begin 
		if (rst = '1') then
			PWM_mode <= "00";
			set_toggle <= '0';
		elsif (clk' EVENT and clk = '1' and ena = '1') then 
			if(ALUFN = "00000") then
				PWM_mode <= "00";
			elsif(ALUFN = "00001") then
				PWM_mode <= "01";
			elsif(ALUFN = "00010") then
				PWM_mode <= "10";
			else 
				PWM_mode <= "11";
			end if;

			if (PWM_mode = "10" and Timer_vec = X) then
				set_toggle <= not set_toggle;
			end if;
		end if;	
	end process;

	PWM_pulse <=
		'1' when ((PWM_mode = "00" and Timer_vec >= X) or (PWM_mode = "01" and (Timer_vec <= X))) else
		set_toggle when(PWM_mode = "10") else '0';
end Inside;

	
