library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

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
	rst, clk, clk2: in std_logic;
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
	
	sram_data: in std_logic_vector(8 downto 0);
	sram_addr: out std_logic_vector(18 downto 0);
	vs, hs: out std_logic;
	r, g, b: out std_logic_vector(2 downto 0));
end entity;

architecture behav of vga_control is
component rom is
PORT
	(
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock		: IN STD_LOGIC;
		q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
	);
end component;

component rom_pat is
PORT (
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
);
end component;
	signal r1, r2, g1, g2, b1, b2: std_logic_vector(2 downto 0);					
	signal hs1,vs1 : std_logic;				
	signal vector_x : integer range 0 to 799;		--X
	signal vector_y : integer range 0 to 524;		--Y
	
	signal ball_addr,pat1_addr,pat2_addr : std_logic_vector (10 downto 0);
	signal ball_data,pat1_data,pat2_data : std_logic_vector (8 downto 0);
	
	-- 对应于屏幕的球的坐标和半径
	signal ball_dis_x : integer range 0 to 639;
	signal ball_dis_y : integer range 0 to 479;
	signal ball_radius : integer range 0 to 100;
	
	-- 对应于屏幕的球拍显示属性
	signal pat1_dis_x, pat2_dis_x: integer range 0 to 639;
	signal pat1_dis_y, pat2_dis_y: integer range 0 to 479;
	signal pat1_radius, pat2_radius : integer range 0 to 100;
	
	signal tmp,tmp2,tmp3 : integer range 0 to 4095;
begin
-- 从内存读取一张固定的背景图片，上面覆盖文字（标题画面）、球和球拍（游戏画面）

	digital_rom_ball : rom port map (ball_addr, clk, ball_data);
	digital_rom_pat1 : rom_pat port map (pat1_addr, clk, pat1_data);
	
	--------------------- 计算球和球拍的位置 ------------------------
	process(ballX, ballY, ballZ)
	begin
		ball_dis_x <= ballX * 640 / ballXRange;
		ball_dis_y <= ballY * 480 / ballYRange;
		ball_radius <= (ballZRange - ballZ) / 8 + 10;
	end process;
	
	process(pat1X, pat1Y, pat1Z)
	begin
		pat1_dis_x <= pat1X * 640 / patXRange;
		pat1_dis_y <= pat1Y * 480 / patYRange;
		pat1_radius <= (patZRange - pat1Z) / 8 + 35;
	end process;
	
	process(pat2X, pat2Y, pat2Z)
	begin
		pat2_dis_x <= pat2X * 640 / patXRange;
		pat2_dis_y <= pat2Y * 480 / patYRange;
		pat2_radius <= (patZRange - pat2Z) / 10 + 18;
	end process;

	----------------------- 处理x方向 ------------------------------
	process(clk, rst)
	begin
	if rst='0' then
		vector_x <= 0;
	  	elsif clk'event and clk='1' then
			if vector_x=799 then
				vector_x <= 0;
	   	else
	    		vector_x <= vector_x + 1;
	   	end if;
	  	end if;
	end process;
	
------------------------ 处理y方向 -----------------------------
	process(clk,rst)
	begin
		if rst='0' then
			vector_y <= 0;
	  	elsif clk'event and clk='1' then
	   	if vector_x=799 then
				if vector_y=524 then
					vector_y <= 0;
				else
					vector_y <= vector_y + 1;
				end if;
	   	end if;
	  	end if;
	end process;
	
---------------------- 处理行场同步信号 ---------------------------
	 process(clk,rst)
	 begin
		  if rst='0' then
		   hs1 <= '1';
		  elsif clk'event and clk='1' then
		   	if vector_x>=656 and vector_x<752 then
		    	hs1 <= '0';
		   	else
		    	hs1 <= '1';
		   	end if;
		  end if;
	 end process;
 
	 process(clk,rst)
	 begin
	  	if rst='0' then
	   		vs1 <= '1';
	  	elsif clk'event and clk='1' then
	   		if vector_y>=490 and vector_y<492 then
	    		vs1 <= '0';
	   		else
	    		vs1 <= '1';
	   		end if;
	  	end if;
	 end process;
	 
	 process(clk,rst)
	 begin
	  	if rst='0' then
	   		hs <= '0';
	  	elsif clk'event and clk='1' then
	   		hs <=  hs1;
	  	end if;
	 end process;

	 process(clk,rst)
	 begin
	  	if rst='0' then
	   		vs <= '0';
	  	elsif clk'event and clk='1' then
	   		vs <=  vs1;
	  	end if;
	 end process;
	 
---------------- 访问rom，获取输出数据 ------------------
	process(clk, vector_x, vector_y)
	begin
		if (clk'event and clk='1') then
			-- 读背景图片
			if (vector_x >= 0 and vector_x < 640 and vector_y >= 0 and vector_y < 480) then
				sram_addr <= std_logic_vector(to_unsigned(vector_x * 480 + vector_y, sram_addr'length));
			end if;
			
			-- 读球图片
			if (vector_x >= (ball_dis_x - ball_radius) and vector_x < (ball_dis_x + ball_radius) and
				vector_y >= (ball_dis_y - ball_radius) and vector_y < (ball_dis_y + ball_radius)) then
				tmp <= (vector_x - ball_dis_x + ball_radius) * 45 / (2 * ball_radius) * 45 + 
						(vector_y - ball_dis_y + ball_radius) * 45 / (2 * ball_radius);
				ball_addr <= std_LOGIC_VECTOR(to_unsigned(tmp, ball_addr'length));
			else
				ball_addr <= (others => '0');
			end if;
			
			-- 读拍图片（拍1）
			if (vector_x >= (pat1_dis_x - pat1_radius) and vector_x < (pat1_dis_x + pat1_radius) and
					vector_y >= (pat1_dis_y - pat1_radius) and vector_y < (pat1_dis_y + pat1_radius)) then
				tmp2 <= (vector_x - pat1_dis_x + pat1_radius) * 45 / (2 * pat1_radius) * 45 + 
						(vector_y - pat1_dis_y + pat1_radius) * 45 / (2 * pat1_radius);
				pat1_addr <= std_LOGIC_VECTOR(to_unsigned(tmp2, pat1_addr'length));
			else
				pat1_addr <= (others => '0');
			end if;
		end if;
	end process;

	process(rst, sram_data, ball_data)
	begin  
		if rst='0' then
			r1 <= "000";
			g1	<= "000";
			b1	<= "000";	
		elsif (vector_x >= 0 and vector_x < 640 and vector_y >= 0 and vector_y < 480) then
			if not (pat1_data = "000000000") then
				r1 <= pat1_data(8 downto 6);
				g1 <= pat1_data(5 downto 3);
				b1 <= pat1_data(2 downto 0);
			elsif not (ball_data = "000000000") then
				r1 <= ball_data(8 downto 6);
				g1 <= ball_data(5 downto 3);
				b1 <= ball_data(2 downto 0);
			else
				r1 <= sram_data(8 downto 6);
				g1 <= sram_data(5 downto 3);
				b1 <= sram_data(2 downto 0);
			end if;
				
--				if (vector_x >= (pat2_dis_x - pat2_radius) and vector_x < (pat2_dis_x + pat2_radius) and
--					vector_y >= (pat2_dis_y - pat2_radius) and vector_y < (pat2_dis_y + pat2_radius)) then
--					-- 显示拍2（下层）
--				end if;
--						
--				
--				if (vector_x >= (pat1_dis_x - pat1_radius) and vector_x < (pat1_dis_x + pat1_radius) and
--					vector_y >= (pat1_dis_y - pat1_radius) and vector_y < (pat1_dis_y + pat1_radius)) then
--					-- 显示拍1（上层）
--				end if;
		else
			r1 <= "000";
			g1	<= "000";
			b1	<= "000";
		end if;
	end process;
---------------------- 输出 --------------------------- 
	process (hs1, vs1, r1, g1, b1)
	begin
		if hs1 = '1' and vs1 = '1' then
			r	<= r1;
			g	<= g1;
			b	<= b1;
		else
			r	<= (others => '0');
			g	<= (others => '0');
			b	<= (others => '0');
		end if;
	end process;
end architecture;