library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity sensor is
port(
	clk 	: in std_logic; --24MHz时钟
	rst 	: in std_logic; --低电平复位
	rx 	: in std_logic; --数据读取，接连uart tx接口
	x, y, z : out std_logic_vector(11 downto 0);
	dbg 	: out std_logic_vector(7 downto 0);
	dbg2 	: out std_logic_vector(7 downto 0)
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
signal ax_h, ay_h, az_h	: integer;--各方向体轴加速度
signal angx, angy, angz 		: integer;--滚转角(x轴)、俯仰角(y轴)、偏航角(z轴)
signal uart_clk 			: std_logic;
signal read_ang, read_acc	: std_logic;
type r_s is (head, data, reading, check_sum); signal read_state : r_s;
type d_s is (acc, ang); signal data_type : d_s;
signal cnt : integer range 0 to 8:= 0;
-----------------------------sin_cos_rom通过查表来获取三角函数数值---------------------
component sin_cos_rom is
port(
	address	: in std_logic_vector(9 downto 0);
	clock		: in std_logic;
	q			: out std_logic_vector(11 downto 0)
);
end component;

---------------------------sin_cos_rom信号-------------------------
signal ax, ay, az 		: integer;--各方向地轴加速度
signal vx, vy, vz 		: integer;--各方向地轴速度
signal px, py, pz 		: integer;--各方向地轴位置
signal sin_cos_address	: std_logic_vector(9 downto 0);
signal sin_cos_value	: std_logic_vector(11 downto 0);
type c_s is (tri_angel, convert); signal compute_state : c_s;
signal cnt_c : integer range 0 to 6:= 0;
signal sinx, cosx, siny, cosy, sinz, cosz : integer range 0 to 1000;--read_ang, read_acc

begin
-----------------------完成元件例化的映射关系-----------------------
	sensor_uart		: uart port map(
		clk => clk,
		rst => rst,
		rx => rx,
		data_valid => data_valid,
		rd => rd_valid,
		uart_clk => uart_clk);

	sensor_sin_cos : sin_cos_rom port map(
		address => sin_cos_address,
		clock => clk,
		q => sin_cos_value);
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
			dbg2 <= x"00";
----------------------------检查数据包头------------------------------
			case read_state is
				when head =>
					dbg2(0) <= '1';
					if rd_valid = x"55" then
						dbg2(1) <= '1';
						--dbg <= rd_valid;
						read_state <= data;
						cnt <= 0;
					end if;
--------------------------确认数据包类型------------------------------
				when data =>
					dbg2(2) <= '1';
					data_buffer(71 downto 64) <= rd_valid;
					case rd_valid is
						when x"51" =>
							dbg2(3) <= '1';
							data_type <= acc;
							--dbg <= rd_valid;
							read_state <= reading;
						when x"53" =>
							data_type <= ang;
							read_state <= reading;
						when others =>
							dbg2(4) <= '1';
							read_state <= head;
					end case;
---------------------------读入数据放入缓存中---------------------------
				when reading =>--
					dbg2(5) <= '1';
					data_buffer(8*cnt+7 downto 8*cnt+0) <= rd_valid;
					cnt <= cnt + 1;
					read_acc <= '0';
					read_ang <= '0';
---------------------------检查数据，合格时进行计算-----------------------
				when check_sum =>
					dbg2(6) <= '1';
					read_state <= head;
					if conv_std_logic_vector(conv_integer(data_buffer(7 downto 0)) + conv_integer(data_buffer(15 downto 8)) + 
						conv_integer(data_buffer(23 downto 16)) + conv_integer(data_buffer(31 downto 24)) +
						conv_integer(data_buffer(39 downto 32)) + conv_integer(data_buffer(47 downto 40)) +
						conv_integer(data_buffer(55 downto 48)) + conv_integer(data_buffer(63 downto 56)) + conv_integer(data_buffer(71 downto 64)) + 85,8) = rd_valid then
						case data_type is
--------------------------解析体轴加速度----------------------------------
							when acc =>
								ax_h <= (conv_integer(data_buffer(15 downto 8))*256 + conv_integer(data_buffer(7 downto 0))) / 209;
								ay_h <= (conv_integer(data_buffer(31 downto 24))*256 + conv_integer(data_buffer(23 downto 16))) / 209;
								az_h <= (conv_integer(data_buffer(47 downto 40))*256 + conv_integer(data_buffer(39 downto 32))) / 209;
								read_acc <= '1';
								--ay <= ()
								dbg <= conv_std_logic_vector((conv_integer(data_buffer(15 downto 8))*256 + conv_integer(data_buffer(7 downto 0))) / 209, 8);
---------------------------解析角度信息-------------------------------------
							when ang =>
								angx <= (conv_integer(data_buffer(15 downto 8))*256 + conv_integer(data_buffer(7 downto 0))) / 182;
								angy <= (conv_integer(data_buffer(31 downto 24))*256 + conv_integer(data_buffer(23 downto 16))) / 182;
								angz <= (conv_integer(data_buffer(47 downto 40))*256 + conv_integer(data_buffer(39 downto 32))) / 182;
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
if cnt = 6 then

elsif rst = '0' then
			
else

	case compute_state is
		when tri_angel=>
			case cnt_c is 
				when 0 =>
					sin_cos_address <= conv_std_logic_vector((angx+180)*2, 10);
					cnt_c <= cnt_c + 1;
				when 1 =>
					sinx <= conv_integer(sin_cos_value(10 downto 0));
					if sin_cos_value(11) = '1' then
						sinx <= -sinx;
					end if;
					cnt_c <= cnt_c + 1;
				when 2 =>
					sin_cos_address <= conv_std_logic_vector((angx+180)*2+1, 10);
					cnt_c <= cnt_c + 1;
				when 3 =>
					cosx <= conv_integer(sin_cos_value(10 downto 0));
					if sin_cos_value(11) = '1' then
						sinx <= -sinx;
					end if;
					cnt_c <= cnt_c + 1;
				when 4 =>
					sin_cos_address <= conv_std_logic_vector((angy+180)*2, 10);
					cnt_c <= cnt_c + 1;
				--when 5 =>
				--	siny <= sin_cos_value;
				--	cnt += 1;
				--when 6 =>
				--	sin_cos_address <= conv_std_logic_vector((angy+180)*2+1, 10);
				--	cnt += 1;
				--when 7 =>
				--	cosy <= sin_cos_value;
				--	cnt += 1;
				--when 8 =>
				--	sin_cos_address <= conv_std_logic_vector((angz+180)*2, 10);
				--	cnt += 1;
				--when 9 =>
				--	sinz <= sin_cos_value;
				--	cnt += 1;
				--when 10 =>
				--	sin_cos_address <= conv_std_logic_vector((angz+180)*2+1, 10);
				--	cnt += 1;
				--when 11 =>
				--	cosz <= sin_cos_value;
				--	cnt += 1;
				--	compute_state <= convert;
				when others => null;
			end case;
		when convert =>
			ax <= ((cosy*cosx)*ax_h+(cosy*sinx)*ay_h+(-1000*siny)*az_h)/1000;
			ay <= ((-1000*cosx*sinz+sinx*siny*cosz)*ax_h+(1000*cosx*cosz+sinx*siny*sinz)*ay_h+(1000*sinx*cosy))/1000000;
			az <= ((1000*sinx*sinz+cosx*siny*cosz)*ax_h+(-1000*sinx*cosz+cosx*siny*sinz)*ay_h+(1000*cosx*cosy))/1000000;
			az <= az - 10000;

	end case;
end if;

end process;

end architecture;