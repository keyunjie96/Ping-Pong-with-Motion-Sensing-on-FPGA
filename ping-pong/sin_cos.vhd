library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity sin_cos is
port(
	clk : in std_logic;
	ang : in integer range -180 to 180;
	sinx, cosx : out integer range -1000 to 1000
	--angx, angy, angz : in integer range -180 to 180;
	--sinx, cosx, siny, cosy, sinz, cosz : out integer range -1000 to 1000
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
--signal sinx_q, cosx_q, siny_q, cosy_q, sinz_q, cosz_q : std_logic_vector(11 downto 0);
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
	--siny_rom : sin_cos_rom port map(
	--	address => conv_std_logic_vector((angy+180)*2, 10),
	--	clock => clk,
	--	q => siny_q);
	--cosy_rom : sin_cos_rom port map(
	--	address => conv_std_logic_vector((angy+180)*2+1, 10),
	--	clock => clk,
	--	q => cosy_q);
	--sinz_rom : sin_cos_rom port map(
	--	address => conv_std_logic_vector((angz+180)*2, 10),
	--	clock => clk,
	--	q => sinz_q);
	--cosz_rom : sin_cos_rom port map(
	--	address => conv_std_logic_vector((angz+180)*2+1, 10),
	--	clock => clk,
	--	q => cosz_q);
--process (angx, angy, angz) is
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

	--if siny_q(11) = '1' then
	--	siny <= -conv_integer(siny_q(10 downto 0));
	--else
	--	siny <= conv_integer(siny_q(10 downto 0));
	--end if;

	--if cosy_q(11) = '1' then
	--	cosy <= -conv_integer(cosy_q(10 downto 0));
	--else
	--	cosy <= conv_integer(cosy_q(10 downto 0));
	--end if;

	--if sinz_q(11) = '1' then
	--	sinz <= -conv_integer(sinz_q(10 downto 0));
	--else
	--	sinz <= conv_integer(sinz_q(10 downto 0));
	--end if;

	--if cosz_q(11) = '1' then
	--	cosz <= -conv_integer(cosz_q(10 downto 0));
	--else
	--	cosz <= conv_integer(cosz_q(10 downto 0));
	--end if;

end process;

	

end architecture ; -- bhv
