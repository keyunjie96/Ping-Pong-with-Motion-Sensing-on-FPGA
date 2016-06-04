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
	
	sram_data: in std_logic_vector(17 downto 0);
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

component rom_score is
PORT (address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
);
end component;

	constant l_score_x : integer := 284;
	constant r_score_x : integer := 325;
	constant score_y : integer := 8;

	signal r1, r2, g1, g2, b1, b2: std_logic_vector(2 downto 0);					
	signal hs1,vs1 : std_logic;				
	signal vector_x : integer range 0 to 799;		--X
	signal vector_y : integer range 0 to 524;		--Y
	
	signal lball_addr,lpat1_addr,lpat2_addr : std_logic_vector (10 downto 0);
	signal rball_addr,rpat1_addr,rpat2_addr : std_logic_vector (10 downto 0);
	signal lball_data,lpat1_data,lpat2_data : std_logic_vector (8 downto 0);
	signal rball_data,rpat1_data,rpat2_data : std_logic_vector (8 downto 0);
	signal score_addr : std_logic_vector (12 downto 0);
	signal score_data : std_logic_vector (8 downto 0);
	
	-- 对应于屏幕的球的坐标和半径
	signal lball_dis_x, rball_dis_x : integer range 0 to 639;
	signal lball_dis_y, rball_dis_y : integer range 0 to 479;
	signal lball_radius, rball_radius : integer range 0 to 100;
	
	-- 对应于屏幕的球拍显示属性
	signal lpat1_dis_x, lpat2_dis_x, rpat1_dis_x, rpat2_dis_x: integer range 0 to 639;
	signal lpat1_dis_y, lpat2_dis_y, rpat1_dis_y, rpat2_dis_y: integer range 0 to 479;
	signal lpat1_radius, lpat2_radius, rpat1_radius, rpat2_radius : integer range 0 to 100;
	
	signal tmp,tmp2,tmp3 : integer range 0 to 4095;
	signal tmp4 : integer range 0 to 511;
	signal tmp_ballx: integer range 0 to ballXRange;
	signal tmp_ballz, tmp_pat1z, tmp_pat2z: integer range 0 to ballZRange;
	signal tmp_ball_dis_x, tmp_pat1_dis_x, tmp_pat2_dis_x: integer range 0 to 699;
	signal tmp_pat1x, tmp_pat2x: integer range 0 to patXRange;

	-- 计算球在屏幕上的坐标	
procedure calcBallPos(signal x: in integer range 0 to ballXRange;
	signal y: in integer range 0 to ballYRange;
	signal z: in integer range 0 to ballZRange;
	signal xp: out integer range 0 to 639;
	signal yp: out integer range 0 to 479;
	signal r: out integer range 0 to 100) is 
begin
	--xp <= ballXRange / 2 + (ballZRange + 2 * (ballZRange - z) / 3) * (ballXRange / 2 - x * 320 / ballXRange) / ballXRange;
	xp <= x * 320 / ballXRange;
	yp <= y * 300 / ballYRange - 50 + (ballZRange - z) * 3 / 2;
	r <= (ballZRange - z) / 8 + 7;
end procedure;

procedure calcPatPos(signal x: in integer range 0 to patXRange;
	signal y: in integer range 0 to patYRange;
	signal z: in integer range 0 to ballZRange;
	signal xp: out integer range 0 to 639;
	signal yp: out integer range 0 to 479;
	signal r: out integer range 0 to 100) is 
begin
	--xp <= ballXRange / 2 + (ballZRange + 2 * (ballZRange - z) / 3) * (ballXRange / 2 - x * 320 / ballXRange) / ballXRange;
	xp <= x * 320 / patXRange;
	yp <= y * 300 / patYRange - 150 + (ballZRange - z) * 2;
	r <= (ballZRange - z) / 4 + 20;
end procedure;

begin
-- 从内存读取一张固定的背景图片，上面覆盖文字（标题画面）、球和球拍（游戏画面）

	digital_rom_l_ball : rom port map (lball_addr, clk, lball_data);
	digital_rom_r_ball : rom port map (rball_addr, clk, rball_data);
	digital_rom_l_pat1 : rom_pat port map (lpat1_addr, clk, lpat1_data);
	digital_rom_l_pat2 : rom_pat port map (lpat2_addr, clk, lpat2_data);
	digital_rom_r_pat1 : rom_pat port map (rpat1_addr, clk, rpat1_data);
	digital_rom_r_pat2 : rom_pat port map (rpat2_addr, clk, rpat2_data);
	digital_rom_score : rom_score port map (score_addr, clk, score_data);
	
	--------------------- 计算球和球拍的位置 ------------------------
	process(ballX, ballY, ballZ)
	begin
		tmp_ballx <= ballXRange - ballX;
		tmp_ballz <= ballZRange - ballZ;
		calcBallPos(ballX, ballY, ballZ, lball_dis_x, lball_dis_y, lball_radius);
		calcBallPos(tmp_ballx, ballY, tmp_ballz, tmp_ball_dis_x, rball_dis_y, rball_radius);
		rball_dis_x <= tmp_ball_dis_x + 320;
	end process;
	
	process(pat1X, pat1Y, pat1Z)
	begin
		tmp_pat1x <= patXRange - pat1X;
		tmp_pat1z <= ballZRange - pat1Z;
		calcPatPos(pat1X, pat1Y, pat1Z, lpat1_dis_x, lpat1_dis_y, lpat1_radius);
		calcPatPos(tmp_pat1x, pat1Y, tmp_pat1z, tmp_pat1_dis_x, rpat1_dis_y, rpat1_radius);
		rpat1_dis_x <= tmp_pat1_dis_x + 320;
	end process;
	
	process(pat2X, pat2Y, pat2Z)
	begin
		tmp_pat2x <= patXRange - pat2X;
		tmp_pat2z <= ballZRange - pat2Z;
		calcPatPos(pat2X, pat2Y, pat2Z, tmp_pat2_dis_x, rpat2_dis_y, rpat2_radius);
		calcPatPos(tmp_pat2x, pat2Y, tmp_pat2z, lpat2_dis_x, lpat2_dis_y, lpat2_radius);
		rpat2_dis_x <= tmp_pat2_dis_x + 320;
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
			if scene='0' then
				-- 读背景图片
				if (vector_x >= 0 and vector_x < 640 and vector_y >= 0 and vector_y < 480) then
					sram_addr <= std_logic_vector(to_unsigned(vector_x * 480 + vector_y, sram_addr'length));
				end if;
				-- 按钮文字
				
			else
				-- 读背景图片
				if (vector_x >= 0 and vector_x < 640 and vector_y >= 0 and vector_y < 480) then
					sram_addr <= std_logic_vector(to_unsigned(vector_x * 480 + vector_y, sram_addr'length));
				end if;
				
				-- 读球图片
				if (vector_x >= (lball_dis_x - lball_radius) and vector_x < (lball_dis_x + lball_radius) and
					vector_y >= (lball_dis_y - lball_radius) and vector_y < (lball_dis_y + lball_radius)) then
					tmp <= (vector_x - lball_dis_x + lball_radius) * 45 / (2 * lball_radius) * 45 + 
							(vector_y - lball_dis_y + lball_radius) * 45 / (2 * lball_radius);
					lball_addr <= std_LOGIC_VECTOR(to_unsigned(tmp, lball_addr'length));
				else
					lball_addr <= (others => '0');
				end if;
				if (vector_x >= (rball_dis_x - rball_radius) and vector_x < (rball_dis_x + rball_radius) and
					vector_y >= (rball_dis_y - rball_radius) and vector_y < (rball_dis_y + rball_radius)) then
					tmp <= (vector_x - rball_dis_x + rball_radius) * 45 / (2 * rball_radius) * 45 + 
							(vector_y - rball_dis_y + rball_radius) * 45 / (2 * rball_radius);
					rball_addr <= std_LOGIC_VECTOR(to_unsigned(tmp, rball_addr'length));
				else
					rball_addr <= (others => '0');
				end if;
				
				-- 读拍图片（拍1）
				if (vector_x >= (lpat1_dis_x - lpat1_radius) and vector_x < (lpat1_dis_x + lpat1_radius) and
						vector_y >= (lpat1_dis_y - lpat1_radius) and vector_y < (lpat1_dis_y + lpat1_radius)) then
					tmp2 <= (vector_x - lpat1_dis_x + lpat1_radius) * 45 / (2 * lpat1_radius) * 45 + 
							(vector_y - lpat1_dis_y + lpat1_radius) * 45 / (2 * lpat1_radius);
					lpat1_addr <= std_LOGIC_VECTOR(to_unsigned(tmp2, lpat1_addr'length));
				else
					lpat1_addr <= (others => '0');
				end if;
				if (vector_x >= (rpat1_dis_x - rpat1_radius) and vector_x < (rpat1_dis_x + rpat1_radius) and
						vector_y >= (rpat1_dis_y - rpat1_radius) and vector_y < (rpat1_dis_y + rpat1_radius)) then
					tmp2 <= (vector_x - rpat1_dis_x + rpat1_radius) * 45 / (2 * rpat1_radius) * 45 + 
							(vector_y - rpat1_dis_y + rpat1_radius) * 45 / (2 * rpat1_radius);
					rpat1_addr <= std_LOGIC_VECTOR(to_unsigned(tmp2, rpat1_addr'length));
				else
					rpat1_addr <= (others => '0');
				end if;
				
				-- 读拍图片（拍2）
				if (vector_x >= (lpat2_dis_x - lpat2_radius) and vector_x < (lpat2_dis_x + lpat2_radius) and
						vector_y >= (lpat2_dis_y - lpat2_radius) and vector_y < (lpat2_dis_y + lpat2_radius)) then
					tmp2 <= (vector_x - lpat2_dis_x + lpat2_radius) * 45 / (2 * lpat2_radius) * 45 + 
							(vector_y - lpat2_dis_y + lpat2_radius) * 45 / (2 * lpat2_radius);
					lpat2_addr <= std_LOGIC_VECTOR(to_unsigned(tmp2, lpat2_addr'length));
				else
					lpat2_addr <= (others => '0');
				end if;
				if (vector_x >= (rpat2_dis_x - rpat2_radius) and vector_x < (rpat2_dis_x + rpat2_radius) and
						vector_y >= (rpat2_dis_y - rpat2_radius) and vector_y < (rpat2_dis_y + rpat2_radius)) then
					tmp2 <= (vector_x - rpat2_dis_x + rpat2_radius) * 45 / (2 * rpat2_radius) * 45 + 
							(vector_y - rpat2_dis_y + rpat2_radius) * 45 / (2 * rpat2_radius);
					rpat2_addr <= std_LOGIC_VECTOR(to_unsigned(tmp2, rpat2_addr'length));
				else
					rpat2_addr <= (others => '0');
				end if;
				
			end if;
		end if;
	end process;

	process(rst, sram_data, rball_data, lball_data)
	begin  
		if rst='0' then
			r1 <= "000";
			g1	<= "000";
			b1	<= "000";	
		elsif (vector_x >= 0 and vector_x < 640 and vector_y >= 0 and vector_y < 480) then
			if scene = '0' then
				r1 <= sram_data(17 downto 15);
				g1 <= sram_data(14 downto 12);
				b1 <= sram_data(11 downto 9);
			else
				if (vector_x >= 310 and vector_x < 325) then
					r1 <= "001";
					g1 <= "001";
					b1 <= "001";
				elsif (vector_x >= l_score_x and vector_x < l_score_x + 20 and vector_y >= score_y and vector_y < score_y + 20) then
					tmp4 <= (vector_x - l_score_x) * 20 + (vector_y - score_y);
					score_addr <= std_logic_vector(to_unsigned(score1, 4)) & std_LOGIC_VECTOR(to_unsigned(tmp4, 9));
					r1 <= score_data(8 downto 6);
					g1 <= score_data(5 downto 3);
					b1 <= score_data(2 downto 0);
				elsif (vector_x >= r_score_x and vector_x < r_score_x + 20 and vector_y >= score_y and vector_y < score_y + 20) then
					tmp4 <= (vector_x - r_score_x) * 20 + (vector_y - score_y);
					score_addr <= std_logic_vector(to_unsigned(score2, 4)) & std_LOGIC_VECTOR(to_unsigned(tmp4, 9));
					r1 <= score_data(8 downto 6);
					g1 <= score_data(5 downto 3);
					b1 <= score_data(2 downto 0);
				else
					-- 这一段的显示逻辑比较迷，我在报告里整理了一份详细的
					if not (lpat1_data = "000000000") then
						r1 <= lpat1_data(8 downto 6);
						g1 <= lpat1_data(5 downto 3);
						b1 <= lpat1_data(2 downto 0);
					elsif not (rpat1_data = "000000000") then
						r1 <= rpat1_data(8 downto 6);
						g1 <= rpat1_data(5 downto 3);
						b1 <= rpat1_data(2 downto 0);
					-- 考虑球被中间挡板遮挡的问题：
					-- 1. 左侧：球的Z在ballZRange/2~ballZRange区间，强行将挡板覆盖在上面，否则覆盖在下面
					-- 2. 右侧：球的Z在0~ballZRange/2区间，强行覆盖上面，否则覆盖下面
					elsif (vector_x >= 22 and vector_x < 300 and vector_y >= 253 and vector_y < 275) then
						if (ballZ < ballZRange / 2) then
							if (not lball_data = "000000000") then
								r1 <= lball_data(8 downto 6);
								g1 <= lball_data(5 downto 3);
								b1 <= lball_data(2 downto 0);
							else
								r1 <= "010";
								g1 <= "010";
								b1 <= "010";
							end if;
						else
							r1 <= "010";
							g1 <= "010";
							b1 <= "010";
						end if;
					elsif (vector_x >= 340 and vector_x < 618 and vector_y >= 253 and vector_y < 275) then
						if (ballZ < ballZRange / 2) then
							r1 <= "010";
							g1 <= "010";
							b1 <= "010";
						else
							if (not rball_data = "000000000") then
								r1 <= rball_data(8 downto 6);
								g1 <= rball_data(5 downto 3);
								b1 <= rball_data(2 downto 0);
							else
								r1 <= "010";
								g1 <= "010";
								b1 <= "010";
							end if;
						end if;
					elsif not (rball_data = "000000000") then
						r1 <= rball_data(8 downto 6);
						g1 <= rball_data(5 downto 3);
						b1 <= rball_data(2 downto 0);
					elsif not (lball_data = "000000000") then
						r1 <= lball_data(8 downto 6);
						g1 <= lball_data(5 downto 3);
						b1 <= lball_data(2 downto 0);
					elsif not (lpat2_data = "000000000") then
						r1 <= lpat2_data(8 downto 6);
						g1 <= lpat2_data(5 downto 3);
						b1 <= lpat2_data(2 downto 0);
					elsif not (rpat2_data = "000000000") then
						r1 <= rpat2_data(8 downto 6);
						g1 <= rpat2_data(5 downto 3);
						b1 <= rpat2_data(2 downto 0);
					else
						r1 <= sram_data(8 downto 6);
						g1 <= sram_data(5 downto 3);
						b1 <= sram_data(2 downto 0);
					end if;
				end if;
			end if;
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