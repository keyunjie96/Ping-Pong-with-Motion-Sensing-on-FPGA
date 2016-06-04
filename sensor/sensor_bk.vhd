library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity sensor is
port(
	clk : in std_logic; --24MHz时钟
	rst : in std_logic; --低电平复位
	rx : in std_logic; --数据读取，接连uart tx接口
	dbg : out std_logic_vector(7 downto 0);
	dbg2 : out std_logic_vector(7 downto 0)
);
end entity;

architecture bev of sensor is

type r_s is (head, data, reading, check_sum); signal read_state : r_s;
type d_s is (acc, ang); signal data_type : d_s;
signal cnt : integer range 0 to 8:= 0;

--uart
component uart is
port(
	clk : in std_logic;
	rst : in std_logic;
	rx : in std_logic;
	rd : out std_logic_vector(7 downto 0);
	data_valid : out std_logic;
	uart_clk : out std_logic
);
end component;
signal data_valid : std_logic;
signal rd_valid : std_logic_vector(7 downto 0);
signal data_buffer : std_logic_vector(63 downto 0);
signal ax, ay, az : integer;
signal uart_clk : std_logic;

begin
	sensor_uart : uart port map(
		clk => clk,
		rst => rst,
		rx => rx,
		data_valid => data_valid,
		rd => rd_valid,
		uart_clk => uart_clk);

process(clk, rx, rst) is
begin
	if cnt = 8 then
		cnt <= 0;
		read_state <= check_sum;
	elsif rst = '0' then
		read_state <= head;
		cnt <= 0;
	elsif rising_edge(uart_clk) then
		if data_valid = '1' then
			dbg2 <= x"00";
			case read_state is
				when head =>--检查数据包头
					dbg2(0) <= '1';
					if rd_valid = x"55" then
						dbg2(1) <= '1';
						--dbg <= rd_valid;
						read_state <= data;
						cnt <= 0;
					end if;
				when data =>--确认数据包类型
					dbg2(2) <= '1';
					case rd_valid is
						when x"51" =>
							dbg2(3) <= '1';
							data_type <= acc;
							dbg <= rd_valid;
							read_state <= reading;
						when x"53" =>
							data_type <= ang;
							read_state <= reading;
						when others =>
							dbg2(4) <= '1';
							read_state <= head;
					end case;
				when reading =>--读入数据放入缓存中
					dbg2(5) <= '1';
					data_buffer(8*cnt+7 downto 8*cnt+0) <= rd_valid;
					cnt <= cnt + 1;
				when check_sum =>--检查数据，合格时进行计算
					dbg2(6) <= '1';
					--read_state <= head;
					dbg <= conv_std_logic_vector(conv_integer(data_buffer(7 downto 0)) + conv_integer(data_buffer(15 downto 8)) + 
						conv_integer(data_buffer(23 downto 16)) + conv_integer(data_buffer(31 downto 24)) +
						conv_integer(data_buffer(39 downto 32)) + conv_integer(data_buffer(47 downto 32)) +
						conv_integer(data_buffer(55 downto 48)) + conv_integer(data_buffer(63 downto 56)),8);
					dbg2 <= rd_valid;
					--if (conv_std_logic_vector(conv_integer(data_buffer(7 downto 0)) + conv_integer(data_buffer(15 downto 8)) + 
					--	conv_integer(data_buffer(23 downto 16)) + conv_integer(data_buffer(31 downto 24)) +
					--	conv_integer(data_buffer(39 downto 32)) + conv_integer(data_buffer(47 downto 32)) +
					--	conv_integer(data_buffer(55 downto 48)) + conv_integer(data_buffer(63 downto 56)),8)) = rd_valid then
					--	case data_type is
					--		when acc =>
					--			dbg2(7) <= '1';
					--			--dbg <= data_buffer(63 downto 56);
					--			dbg <= rd_valid;
					--			ax <= (conv_integer(data_buffer(15 downto 8))*256 + conv_integer(data_buffer(7 downto 0))) * 16 * 10 / 32768;
					--			--dbg <= conv_std_logic_vector(ax, 8);
					--		when ang => null;
					--		when others => null;
					--	end case;
					--end if;
			end case;
		end if;
		--case r_s is
		--	when head =>

		--end case;
	end if;
end process;
end architecture;