--贡献者：柯云劼
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity sensor is
generic(
	patvRange : integer := 14
);

port(
	clk 	: in std_logic; --100MHz时钟
	rst 	: in std_logic; --低电平复位
	rx 	: in std_logic; --数据读取，接连uart tx接口
	x, y, z : out integer;
	is_hit : out std_logic;
	pat_v : out integer range 0 to patvRange
);
end entity;

architecture bev of sensor is
-------------------------------调用uart接口解析数据-------------------------------
component uart is
port(
	clk 			: in std_logic;
	rst 			: in std_logic;
	rx 			: in std_logic;
	rd 			: out std_logic_vector(7 downto 0);
	data_valid 	: out std_logic;
	uart_clk 	: out std_logic
);
end component;
----------------------------uarts信号--------------------------
signal data_valid 		: std_logic;
signal rd_valid 			: std_logic_vector(7 downto 0);
signal data_buffer 		: std_logic_vector(71 downto 0);
signal ax_h, ay_h, az_h	: integer range -160 to 160;--各方向体轴加速度
signal angx, angy, angz : integer range -180 to 180;--滚转角(x轴)、俯仰角(y轴)、偏航角(z轴)
signal uart_clk 			: std_logic;
signal read_ang, read_acc	: std_logic;
type r_s is (head, data, reading, check_sum); signal read_state : r_s;
type d_s is (acc, ang); signal data_type : d_s;
signal cnt : integer range 0 to 8:= 0;
---------------------------sin_cos信号&物理运算模块-------------------------
type c_s is (convert); signal compute_state : c_s;
signal phy_cnt			: integer range 0 to 100000000;--指示一秒



begin
-----------------------完成元件例化的映射关系-----------------------
	sensor_uart		: uart port map(
		clk => clk,
		rst => rst,
		rx => rx,
		data_valid => data_valid,
		rd => rd_valid,
		uart_clk => uart_clk);
---------------------------利用uart元件读取包信息-----------------------
read_package : process(clk, rx, rst) is
variable tp : integer;
begin
----------------------------读完包中数据字节-----------------------------
	if cnt = 8 then
		cnt <= 0;
		read_state <= check_sum;
	elsif rst = '0' then
		read_state <= head;
		cnt <= 0;
		read_acc <= '0';
		read_ang <= '0';
	elsif rising_edge(uart_clk) then
		if data_valid = '1' then
----------------------------检查数据包头------------------------------
			case read_state is
				when head =>
					if rd_valid = x"55" then
						read_state <= data;
						cnt <= 0;
					end if;
--------------------------确认数据包类型------------------------------
				when data =>
					data_buffer(71 downto 64) <= rd_valid;
					case rd_valid is
						when x"51" =>
							data_type <= acc;
							read_state <= reading;
						when x"53" =>
							data_type <= ang;
							read_state <= reading;
						when others =>
							read_state <= head;
					end case;
---------------------------读入数据放入缓存中---------------------------
				when reading =>--
					data_buffer(8*cnt+7 downto 8*cnt+0) <= rd_valid;
					cnt <= cnt + 1;
					read_acc <= '0';
					read_ang <= '0';
---------------------------检查数据，合格时进行计算-----------------------
				when check_sum =>
					read_state <= head;
					if conv_std_logic_vector(conv_integer(data_buffer(7 downto 0)) + conv_integer(data_buffer(15 downto 8)) + 
						conv_integer(data_buffer(23 downto 16)) + conv_integer(data_buffer(31 downto 24)) +
						conv_integer(data_buffer(39 downto 32)) + conv_integer(data_buffer(47 downto 40)) +
						conv_integer(data_buffer(55 downto 48)) + conv_integer(data_buffer(63 downto 56)) + conv_integer(data_buffer(71 downto 64)) + 85,8) = rd_valid then
						case data_type is
--------------------------解析体轴加速度-------················································---------------------------
							when acc =>
									ax_h <= (conv_integer(signed(data_buffer(15 downto 8)))*256 + conv_integer(data_buffer(7 downto 0))) / 209;
									ay_h <= (conv_integer(signed(data_buffer(31 downto 24)))*256 + conv_integer(data_buffer(23 downto 16))) / 209;	
									az_h <= (conv_integer(signed(data_buffer(47 downto 40)))*256 + conv_integer(data_buffer(39 downto 32))) / 209;	
									if (ax_h < -10 or ax_h > 10) then 
										is_hit <= '1';
										if(ax_h < -20 or ax_h > 20) then
											pat_v <= patvRange;
										else
											pat_v <= (abs(ax_h)-10) + 4;
										end if;
									else 
										is_hit <= '0';
										pat_v <= 4;
									end if;
								read_acc <= '1';
								--ay <= ()
---------------------------解析角度信息-------------------------------------
							when ang =>
								angx <= (conv_integer(signed(data_buffer(15 downto 8)))*256 + conv_integer(data_buffer(7 downto 0))) / 182;
								read_ang <= '1';
							when others => null;
						end case;
					end if;
				when others => null;
			end case;
		end if;
	end if;
end process;
-----------------------------作物理运算:体轴到地轴的换算，以及作二次黎曼积分从地轴加速度到地轴位置------------------------------------
physics : process(clk, rst) is
begin

if rst = '0' then
	compute_state <= convert;

elsif rising_edge(clk) then
	phy_cnt <= phy_cnt + 1;
	if(angx < 0) then
		x <= ( angx + 180 ) * 73 / 100 + 80;
	else
		x <= ( angx - 70 ) * 73 / 100 ;
	end if;
end if;
end process;
  
end architecture;