library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity pingpong is
port(
	------------------------    Clock Input        ------------------------
	clk1: in std_logic;	-- 100M
	clk2: in std_logic;  -- 24M
	
	------------------------    reset      --------------------------------
	rst: in std_logic;
	
	------------------------    PS2        --------------------------------
	datain: in std_logic;
	ps2clk: in std_logic;
	
	------------------------   Sensor    ----------------------------------
	sensor_in: in std_logic;
	
	--------------------------  SRAM    -----------------------------------
	sram_data: inout std_logic_vector(31 downto 0);
	sram_addr: out std_logic_vector(20 downto 0);
	sram_RW: out std_logic_vector(1 downto 0);
	
	------------------------    VGA      ----------------------------------
	vga_hs,vga_vs: out STD_LOGIC;
	vga_r,vga_g,vga_b: out STD_LOGIC_vector(2 downto 0);
	
	------------------------   DEBUG    -----------------------------------
	debug_clk: in std_logic
);
end entity;

architecture behav of pingpong is

----------------- Keyboard component ------------------
component top is
port(
	datain,clkin,fclk,rst_in: in std_logic;
	oper:out std_logic_vector(2 downto 0)
);
end component;

---------------- game_control component ----------------
component game_control is
port(
	rst, clk1, clk2: in std_logic;
	key_in: in std_logic_vector(2 downto 0);
	sensor_in: in std_logic;
	sram_data: in std_logic_vector(17 downto 0);
	sram_addr: out std_logic_vector(18 downto 0);
	vga_hs, vga_vs: out std_logic;
	vga_r, vga_g, vga_b: out std_logic_vector(2 downto 0));
end component;

---------------- sram_control component ----------------
component sram_control is
port (
	clk: in std_logic;
	-- 对应sram
	data: inout std_logic_vector(17 downto 0);
	addr: out std_logic_vector(20 downto 0);
	RW: out std_logic_vector(1 downto 0);
	
	-- 对应内部
	in_data: out std_logic_vector(17 downto 0);
	in_addr: in std_logic_vector(18 downto 0));
end component;

signal keyboard_oper: std_logic_vector(2 downto 0);
signal sram_data_temp: std_logic_vector(17 downto 0);
signal sram_addr_temp: std_logic_vector(18 downto 0);

begin
	----------------------------------------------------------------
   -- Keyboard control
   ----------------------------------------------------------------
	keyboard: top port map (
		datain => datain,
		clkin => ps2clk,
		fclk => clk1,
		rst_in => rst,
		oper => keyboard_oper);
		
	----------------------------------------------------------------
   -- SRAM control
   ----------------------------------------------------------------
	sram: sram_control port map (
		clk => clk2,
		data => sram_data(17 downto 0),
		addr => sram_addr,
		RW => sram_RW,
		in_data => sram_data_temp,
		in_addr => sram_addr_temp);
	

	----------------------------------------------------------------    
   -- Game
   ----------------------------------------------------------------
	game: game_control port map (
		rst => rst,
		clk1 => clk1,
		clk2 => clk2,
		sensor_in => sensor_in,
		key_in => keyboard_oper,
		sram_data => sram_data_temp,
		sram_addr => sram_addr_temp,
		vga_hs => vga_hs,
		vga_vs => vga_vs,
		vga_r => vga_r,
		vga_g => vga_g,
		vga_b => vga_b);
end architecture;