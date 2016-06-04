library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity top is
port(
datain,clkin,fclk,rst_in: in std_logic;
oper: out std_logic_vector(2 downto 0)
);
end top;

architecture behave of top is
component Keyboard is
port (
	datain, clkin : in std_logic ; -- PS2 clk and data
	fclk, rst : in std_logic ;  -- filter clock
--	fok : out std_logic ;  -- data output enable signal
	scancode : out std_logic_vector(7 downto 0) -- scan code signal output
	) ;
end component ;

component seg7 is
port(
code: in std_logic_vector(3 downto 0);
seg_out : out std_logic_vector(6 downto 0)
);
end component;

signal scancode : std_logic_vector(7 downto 0);
signal rst : std_logic;
signal clk_f: std_logic;
begin
rst<=not rst_in;

u0: Keyboard port map(datain,clkin,fclk,rst,scancode);

process(scancode)
begin
	case scancode(7 downto 0) is
	-- 处理回车键和ESC键
		when "01011010" => oper <= "100";  -- enter
		--when "01110110" => oper <= "111";  -- esc
	-- WASDQE：调试用
		when "00011100" => oper <= "001"; -- A
		when "00100011" => oper <= "010"; -- D
		when "00011101" => oper <= "101"; -- W
		when "00011011" => oper <= "110"; -- S
		when "00010101" => oper <= "011"; -- Q
		when "00100100" => oper <= "111"; -- E
		when others => oper <="000";
	end case;
end process;

end behave;

