--贡献者：柯云劼
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity sin_cos is
port(
	clk : in std_logic;
	ang : in integer range -180 to 180;
	sinx, cosx : out integer range -1000 to 1000
);
end entity;

architecture bhv of sin_cos is

component sin_cos_rom is
port(
	address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
	clock		: IN STD_LOGIC  := '1';
	q		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
);
end component; 
signal sinx_q, cosx_q: std_logic_vector(11 downto 0);
begin

	sinx_rom : sin_cos_rom port map(
		address => conv_std_logic_vector((ang+180)*2, 10),
		clock => clk,
		q => sinx_q);
	cosx_rom : sin_cos_rom port map(
		address => conv_std_logic_vector((ang+180)*2+1, 10),
		clock => clk,
		q => cosx_q);
process (ang) is
begin
	if sinx_q(11) = '1' then
		sinx <= -conv_integer(sinx_q(10 downto 0));
	else
		sinx <= conv_integer(sinx_q(10 downto 0));
	end if;

	if cosx_q(11) = '1' then
		cosx <= -conv_integer(cosx_q(10 downto 0));
	else
		cosx <= conv_integer(cosx_q(10 downto 0));
	end if;
end process;

end architecture ; -- bhv
