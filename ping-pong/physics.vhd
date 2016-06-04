library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- physics 是底层的物理类，接受来自传感器的输入，给出每一时刻球和拍的位置
entity physics is
generic(
	ballXRange: integer := 160;
	ballYRange: integer := 120;
	ballZRange: integer := 220;
	patXRange: integer := 160;						
	patYRange: integer := 120;
	patZRange: integer := 110);
port(
	rst, clk: in std_logic;
	rx1: in std_logic;
	rx2: in std_logic;
	start_clk: in std_logic;
	ballX: out integer range 0 to ballXRange;
	ballY: out integer range 0 to ballYRange;
	ballZ: out integer range 0 to ballZRange;
	pat1X: out integer range 0 to patXRange;
	pat1Y: out integer range 0 to patYRange;
	pat1Z: out integer range 0 to patZRange;
	pat2X: out integer range 0 to patXRange;
	pat2Y: out integer range 0 to patYRange;
	pat2Z: out integer range 0 to patZRange);
end entity;

architecture behav of physics is
signal cnt : integer range 0 to 100000000;

signal ball_ang : integer range -180 to 180; signal sinx, cosx : integer range -1000 to 1000;
signal ball_X: integer range 0 to ballXRange;
signal ball_Y: integer range 0 to ballYRange;
signal ball_Z: integer range 0 to ballZRange;
signal ball_v: integer range 0 to 20;

signal pat1_X: integer range 0 to patXRange;
signal pat1_Y: integer range 0 to patYRange;
signal pat1_Z: integer range 0 to patZRange;
signal pat1_hit : std_logic;
signal pat2_X: integer range 0 to patXRange;
signal pat2_Y: integer range 0 to patYRange;
signal pat2_Z: integer range 0 to patZRange;
signal pat2_hit : std_logic;
type b_s is (waiting, flying, pat1Range, pat2Range, left_border, right_border); signal ball_state : b_s;
type c_s is (pat1, pat2); signal catch_state : c_s;
signal rotate_cw : std_logic;
-- 还需要一个component 获取球拍数据
component sin_cos is
port(
	clk : in std_logic;
	ang : in integer range -180 to 180;
	sinx, cosx : out integer range -1000 to 1000
);
end component;
component sensor is
port(
	clk 	: in std_logic; --100MHz时钟
	rst 	: in std_logic; --低电平复位
	rx 	: in std_logic; --数据读取，接连uart tx接口
	x, y, z : out integer;
	is_hit : out std_logic
);
end component;
begin
	sin_cos_component 	: sin_cos port map(
		clk => clk,
		ang => ball_ang,
		sinx => sinx,
		cosx => cosx
	);
	sensor_pat1_component	: sensor port map(
		clk => clk,
		rst => rst,
		rx => rx1,
		x => pat1_X,
		y => pat1_Y,
		z => pat1_Z,
		is_hit => pat1_hit
	);
	sensor_pat2_component	: sensor port map(
		clk => clk,
		rst => rst,
		rx => rx1,
		x => pat2_X,
		y => pat2_Y,
		z => pat2_Z,
		is_hit => pat2_hit
	);
	
------------------  复位以及获得拍信息  ----------------------
	process(rst, clk)
	begin
		if (rst = '0') then
--			ballX <= ballXRange / 2;
--			ballY <= ballYRange / 3;
--			ballZ <= ballZRange / 5;
			
			pat1X <= 140;
			pat1Y <= 90;
			pat1Z <= 20;
			
			pat2X <= 140;
			pat2Y <= 90;
			pat2Z <= 20;
		elsif rising_edge(clk) then
			pat1X <= pat1_X;
			pat2X <= pat2_X;
			pat1Y <= 0+10;
			pat2Y <= patYRange-10;
			--pat1X <= x/(720/(patXRange));--+patXRange/2;
			--pat1Y <= y/(720/(patYRange));--+patYRange/2;																																																																									
			--pat1Z <= z/(720/(patZRange));--+patZRange/2;
		end if;
	end process;
	
-------------------	计算球的状态   -----------------
	process(rst, clk)
	begin
		ballX <= ball_X;
		ballY <= ball_Y;
		ballZ <= ball_Z;
		if (rst = '0') then
			ball_X <= ballXRange / 2;
			ball_state <= waiting;
			ball_ang <= 35;
			cnt <= 0;
			rotate_cw <= '1';
			ball_v <= 8;
		elsif rising_edge(clk) then
			cnt <= cnt + 1;
			case ball_state is
			--------------球等待开始---------------
				when waiting =>
					if pat1_hit = '1' and ball_X > 0 and ball_X < ballXRange then
							ball_state <= pat1Range;
							catch_state <= pat2;
					elsif cnt mod 5000000  = 0 then
						if (rotate_cw = '1') then
							ball_ang <= ball_ang - 5;
							if (ball_ang < 35) then
								rotate_cw <= '0';
							end if;
						elsif (rotate_cw = '0') then
							ball_ang <= ball_ang + 5;
							if (ball_ang > 145) then
								rotate_cw <= '1';
							end if;
						end if;
					end if;
					ball_X <= pat1_X + 20 * cosx / 1000;
					ball_Z <= 20 + 20 * sinx / 1000;
				when others =>
					if cnt mod 10000000 = 0 then
					--------------球超出上下边界，游戏结束，回归等待---------------
						if ((ball_z < 30 or ball_Z > ballZRange - 30) and ball_state /= waiting) then
							ball_state <= waiting;
						--------------球超出左右边界---------------
						elsif ((ball_X < 30)  and ball_state /= left_border) then
							if ball_ang > 0 then
								ball_ang <= 180 - ball_ang;
							else
								ball_ang <= -180 - ball_ang;
							end if;
							ball_state <= left_border;
						elsif ((ball_X > ballXRange - 30) and ball_state /= right_border) then
							if ball_ang > 0 then
								ball_ang <= 180 - ball_ang;
							else
								ball_ang <= -180 - ball_ang;
							end if;
							ball_state <= right_border;
						--------------球被拍接住---------------
						--elsif ((ball_Z < 20 and ball_X > pat1_X - 10 and ball_X < pat1_X + 10) and ball_state /= pat1Range and catch_state = pat1) then
						elsif ball_Z < 50 and ball_state /= pat1Range then --and catch_state = pat1 then 
							ball_ang <= -ball_ang;
							ball_state <= pat1Range;
							catch_state <= pat2;
						--elsif ((ball_Z > ballZRange - 20 and ball_X > pat2_X - 10 and ball_X < pat2_X + 10) and ball_state /= pat2Range and catch_state = pat2) then
						elsif ball_Z > ballZRange - 50 and ball_state /= pat2Range then --and catch_state = pat2 then
							ball_ang <= -ball_ang;
							ball_state <= pat2Range;
							catch_state <= pat1;
						--------------球在飞行，平凡情况---------------
						else
							--ball_state <= flying;
						end if;
						ball_X <= ball_X + ball_v * cosx / 1000;
						ball_Z <= ball_Z + ball_v * sinx / 1000;
					end if;
			end case;
		end if;

	end process;
end architecture;