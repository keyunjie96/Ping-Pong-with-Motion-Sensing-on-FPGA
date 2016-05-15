library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- vga_control 控制vga输出
entity vga_control is
generic(
	ballXRange: integer := 160;
	ballYRange: integer := 120;
	ballZRange: integer := 220;
	patXRange: integer := 160;
	patYRange: integer := 120;
	patZRange: integer := 110);
port(
	rst, clk: in std_logic;
	scene: in bit;	-- 0：标题界面， 1：游戏界面
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
end entity;

architecture behav of vga_control is
signal color: std_logic_vector(8 downto 0);
begin
-- 从内存读取一张固定的背景图片，上面覆盖文字（标题画面）、球和球拍（游戏画面）
end architecture;