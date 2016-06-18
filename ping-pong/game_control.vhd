--贡献者：王子云
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity game_control is
port(
	rst, clk1, clk2: in std_logic;	--clk1: 100M, clk2: 24M
	key_in: in std_logic_vector(2 downto 0);
	sensor_in: in std_logic;
	sensor_in_1: in std_logic;
	sensor_in_2: in std_logic;
	start_clk: in std_logic;
	sram_data: in std_logic_vector(17 downto 0);
	sram_addr: out std_logic_vector(18 downto 0);
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
	rst, clk, clk2: in std_logic;
	scene: in std_logic_vector(1 downto 0);
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
	
	sram_data: in std_logic_vector(17 downto 0);
	sram_addr: out std_logic_vector(18 downto 0);
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
	start: in std_logic;
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
end component;

	constant ballXRange: integer := 160;
	constant ballYRange: integer := 120;
	constant ballZRange: integer := 220;
	constant patXRange: integer := 160;
	constant patYRange: integer := 120;
	constant patZRange: integer := 110;
	
	signal ballX: integer range 0 to ballXRange;
	signal ballY: integer range 0 to ballYRange;
	signal ballZ: integer range 0 to ballZRange;
	signal pat1X: integer range 0 to patXRange;
	signal pat1Y: integer range 0 to patYRange;
	signal pat1Z: integer range 0 to patZRange;
	signal pat2X: integer range 0 to patXRange;
	signal pat2Y: integer range 0 to patYRange;
	signal pat2Z: integer range 0 to patZRange;
	signal s1, s2 : integer range 0 to 15;
	signal scene: std_logic_vector(1 downto 0) := "00";
	signal start: std_logic := '0';
	
	signal key_in_tmp: std_logic_vector(2 downto 0) := "000";
	signal key_oper: std_logic_vector(2 downto 0) := "000";
	
begin

	vga: vga_control generic map (
		ballXRange, ballYRange, ballZRange,
		patXRange, patYRange, patZRange)
						port map(
		rst, clk2, clk1, scene, s1, s2,
		ballX, ballY, ballZ,
		pat1X, pat1Y, pat1Z,
		pat2X, pat2Y, pat2Z,
		sram_data, sram_addr,
		vga_vs, vga_hs, vga_r, vga_g, vga_b);
	
	logic: game_logic generic map (
		ballXRange, ballYRange, ballZRange,
		patXRange, patYRange, patZRange)
						port map(
		rst, clk1, start, s1, s2, sensor_in_1, sensor_in_2,
		ballX, ballY, ballZ,
		pat1X, pat1Y, pat1Z,
		pat2X, pat2Y, pat2Z);
	
----------------- 解析键盘输入 ------------------

	process(key_in, clk1)
	begin
		if rising_edge(clk1) then
			if (key_in_tmp /= key_in) then
				key_oper <= key_in;
				key_in_tmp <= key_in;
			else
				key_oper <= "000";
			end if;
		end if;
	end process;

	process(rst, key_in, clk1, s1, s2)
	begin
		if rst = '0' then
			start <= '0';
			scene <= "00";
		elsif rising_edge(clk1) then
			if start = '1' then
				start <= '0';
			end if;
		end if;
		if (s1 = 7) then
			scene <= "10";
		end if;
		if (s2 = 7) then
			scene <= "10";
		end if;
		-- 处理回车键
		if key_oper = "100" and scene = "00" then
			start <= '1';
			scene <= "01";
		end if;
		if key_oper = "100" and scene = "10" then
			start <= '1';
			scene <= "01";
		end if;
		-- 处理esc
		if key_oper = "111" then
			start <= '0';
			scene <= "00";
		end if;
	end process;

end architecture;