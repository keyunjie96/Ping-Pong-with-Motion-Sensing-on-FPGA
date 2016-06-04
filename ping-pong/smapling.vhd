library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity sampling is
	port(
		clk : in std_logic; --24MHz时钟
		rst : in std_logic;
		rx : in std_logic;
		rd : out std_logic_vector(7 downto 0);
		data_valid : out std_logic
		);
end entity;

architecture bev of sampling is
signal cnt : integer range 0 to 2499 := 0;--分频技术，24MHz时钟采用2500分频后为9600波特率
signal pointer : integer range 0 to := 0;
--signal start : std_logic;
begin
process(clk, rst) is
	if rst = '0' then

	elsif rising_edge(clk) then
		cnt <= cnt + 1;
	end if;
end process;

process(cnt)
	if cnt = 2499 then



	end if;
end architecture;