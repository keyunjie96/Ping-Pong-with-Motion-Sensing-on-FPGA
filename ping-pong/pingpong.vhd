library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity pingpong is
port(
	------------------------    Clock Input        ------------------------
	clk1: in std_logic;
	clk2: in std_logic;
	
	------------------------    reset      --------------------------------
	rst: in std_logic;
	
	------------------------    PS2        --------------------------------
	datain: in std_logic;
	
	------------------------    VGA        --------------------------------
	vga_hs,vga_vs: out STD_LOGIC; 
	vga_r,vga_g,vga_b: out STD_LOGIC_vector(2 downto 0)
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
	rst, clk: in std_logic;
	key_in: in std_logic_vector(2 downto 0);
	vga_hs, vga_vs: out std_logic;
	vga_r, vga_g, vga_b: out std_logic_vector(2 downto 0));
end component;

signal keyboard_oper: std_logic_vector(2 downto 0);

begin
	----------------------------------------------------------------
   -- Keyboard control
   ----------------------------------------------------------------
	keyboard: top port map (
		datain => datain,
		clkin => clk1,
		fclk => clk2,
		rst_in => rst,
		oper => keyboard_oper);

	----------------------------------------------------------------    
   -- Game
   ----------------------------------------------------------------
	game: game_control port map (
		rst => rst,
		clk => clk1,
		key_in => keyboard_oper,
		vga_hs => vga_hs,
		vga_vs => vga_vs,
		vga_r => vga_r,
		vga_g => vga_g,
		vga_b => vga_b);
end architecture;