library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity uart is
	port(
		clk : in std_logic; --24MHz时钟
		rst : in std_logic;
		rx : in std_logic;
		rd : out std_logic_vector(7 downto 0);
		data_valid : out std_logic;
		uart_clk : out std_logic
		);
end entity;

architecture bev of uart is
	signal cnt : integer range 0 to 2499 := 0;--分频技术，24MHz时钟采用2500分频后为9600波特率
	signal pointer : integer range -1 to 8 := -1;
	signal rd_tp : std_logic_vector(7 downto 0);
	signal rx_check : std_logic;
	--signal start : std_logic;
begin
process(clk, rst) is
begin
	uart_clk <= rx_check;
	if rising_edge(clk) then
		cnt <= cnt + 1;
		if cnt = 2499 then
			rx_check <= '1';
			cnt <= 0;
		elsif cnt = 20 then
			rx_check <= '0';
		end if;

	end if;
end process;

process(clk, rst) is
begin
	if rst = '0' then
		data_valid <= '0';
		rd_tp <= x"00";
		pointer <= -1;
	elsif rising_edge(rx_check) then --上升沿时检查数据
		data_valid <= '0';
		case pointer is 
			when -1 =>--检查起始信号，如果电平拉低说明开始一个字节
				--data_valid <= '0';
				if rx = '0' then
					pointer <= pointer + 1;
				end if;
			when 8 =>--检查结束信号，如果电平拉高说明结束一个字节
				if rx = '1' then
					data_valid <= '1';
					rd <= rd_tp;
				--else--信号有毒，抛弃该字节
				--	data_valid <= '0';
				end if;
				pointer <= -1;
			when others => null;--字节读入中
				rd_tp(pointer) <= rx;
				pointer <= pointer + 1;
		end case;
	end if;
end process;
end architecture;