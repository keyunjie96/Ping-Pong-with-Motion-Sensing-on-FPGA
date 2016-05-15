library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity game_control is
port(
	rst, clk: in std_logic;
	key_in: in std_logic_vector(2 downto 0);
	vga_hs, vga_vs: out std_logic;
	vga_r, vga_g, vga_b: out std_logic_vector(2 downto 0));
end entity;

architecture behav of game_control is
-----------------  vga component ------------------
component vga_control is
generic(
	ballXRange: integer := 160;
	ballYRange: integer := 120;
	ballZRange: integer := 220;
	patXRange: integer := 160;
	patYRange: integer := 120;
	patZRange: integer := 110);
port(
	rst, clk: in std_logic;
	scene: in bit;
	score1, score2: in integer range 0 to 15;
	ballX: in integer range 0 to ballXRange;
	ballY: in integer range 0 to ballYRange;
	ballZ: in integer range 0 to ballZRange;
	pat1X: in integer range 0 to patXRange;
	pat1Y: in integer range 0 to patYRange;
	pat1Z: in integer range 0 to patZRange;
	pat2X: in integer range 0 to patXRange;
	pat2Y: in integer range 0 to patYRange;
	pat2Z: in integer range 0 to patZRange;
	
	vs, hs: out std_logic;
	r, g, b: out std_logic_vector(2 downto 0));
end component;

----------------  logic component -----------------
component game_logic is
generic(
	ballXRange: integer := 160;
	ballYRange: integer := 120;
	ballZRange: integer := 220;
	patXRange: integer := 160;
	patYRange: integer := 120;
	patZRange: integer := 110);
port(
	rst, clk: in std_logic;
	score1, score2: out integer range 0 to 15;
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

begin
-- TODO: 解析键盘输入，负责传递游戏开始信号
end architecture;