library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- game_logic 用来运行游戏逻辑
-- 负责给出每一时刻双方的比分、球和拍的位置
entity game_logic is
generic(
	ballXRange: integer := 160;
	ballYRange: integer := 120;
	ballZRange: integer := 220;
	patXRange: integer := 160;
	patYRange: integer := 120;
	patZRange: integer := 110);
port(
	rst, clk: in std_logic;
	start: in std_logic; -- 游戏开始的信号
	score1, score2: out integer range 0 to 15;
	sensor_in_1: in std_logic;
	sensor_in_2: in std_logic;
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

architecture behav of game_logic is

---------------  physics component ----------------
component physics is
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
	ballX: out integer range 0 to ballXRange;
	ballY: out integer range 0 to ballYRange;
	ballZ: out integer range 0 to ballZRange;
	pat1X: out integer range 0 to patXRange;
	pat1Y: out integer range 0 to patYRange;
	pat1Z: out integer range 0 to patZRange;
	pat2X: out integer range 0 to patXRange;
	pat2Y: out integer range 0 to patYRange;
	pat2Z: out integer range 0 to patZRange;
	status: out std_logic_vector(1 downto 0));
end component;

-- 每一球的各个状态
type point_states is (idle, Ago, Bgo, finish);
signal point_s : point_states := idle;
signal inner_status: std_logic_vector(1 downto 0);

signal server: bit; -- 发球方
signal s1, s2: integer range 0 to 15;

signal x: integer range 0 to ballXRange;
signal y: integer range 0 to ballYRange;
signal z: integer range 0 to ballZRange;
signal p1x: integer range 0 to patXRange;
signal p1y: integer range 0 to patYRange;
signal p1z: integer range 0 to patZRange;
signal p2x: integer range 0 to patXRange;
signal p2y: integer range 0 to patYRange;
signal p2z: integer range 0 to patZRange;

begin

	physics_logic: physics generic map(
		ballXRange, ballYRange, ballZRange,
		patXRange, patYRange, patZRange)
			port map(rst, clk, sensor_in_1, sensor_in_2,
			x, y, z,	p1x, p1y, p1z, p2x, p2y, p2z, inner_status);
			
	ballX <= x;
	ballY <= y;
	ballZ <= z;
	pat1X <= p1x;
	pat1Y <= p1y;
	pat1Z <= p1z;
	pat2X <= p2x;
	pat2Y <= p2y;
	pat2Z <= p2z;
	
	process(start, z, p1z, p2z, clk)
	begin
		-- 游戏开始，复位
		if (start = '1') then
			s1 <= 0;
			s2 <= 0;
			point_s <= finish;
		elsif rising_edge(clk) then
		-- 判断得分 
			if (inner_status = "01") and (s1 /= 7) and (s2 /= 7) then
				point_s <= idle;
			elsif (point_s = idle) then
				if (inner_status = "10") then -- 2获胜
					s2 <= s2 + 1;
					point_s <= finish;
				end if;
				if (inner_status = "11") then -- 1获胜
					s1 <= s1 + 1;
					point_s <= finish;
				end if;
			end if;
		end if;
	end process;
	score1 <= s1;
	score2 <= s2;

end architecture;