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
	start_clk : in std_logic;
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
end component;

-- 每一球的各个状态
type point_states is (idle, Ago, Bgo, finish);
signal point_s : point_states := idle;

signal server: bit; -- 发球方

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
			port map(rst, clk, sensor_in_1, sensor_in_2, start_clk, x, y, z, 
		p1x, p1y, p1z, p2x, p2y, p2z);
	ballX <= x;
	ballY <= y;
	ballZ <= z;
	pat1X <= p1x;
	pat1Y <= p1y;
	pat1Z <= p1z;
	pat2X <= p2x;
	pat2Y <= p2y;
	pat2Z <= p2z;
	
------------ 游戏开始，复位 --------------
	process(start)
	begin
		if (rising_edge(start)) then
			score1 <= 0;
			score2 <= 0;
			point_s <= idle;
		end if;
	end process;

-------------- 判断得分 -----------------
--	process(ballX, ballY, ballZ, pat1X, pat1Y, pat1Z, pat2X, pat2Y, pat2Z)
--	begin
--		if point_s = Ago then
--			if (ballZ > ballZRange - pat2Z) then
--				if () -- 球与拍子不接触
--					score1 <= score1 + 1;
--					point_s <= finish;
--				else
--					point_s <= idle;
--				end if;
--			end if;
--		elsif point_s = Bgo then
--			if (ballZ < pat1Z) then
--				if () -- 球与拍子不接触
--					score2 <= score2 + 1;
--					point_s <= finish;
--				else
--					point_s <= idle;
--				end if;
--			end if;
--		end if;
--	end process;

end architecture;