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
-- 这里需要一些signal 处理球、球拍各自的位置、速度、加速度（maybe球拍只需要加速度？计算动量？）
-- 还需要一个component 获取球拍数据

begin

------------------  复位  ----------------------
	process(rst)
	begin
		if (rst = '0') then
			ballX <= ballXRange / 2;
			ballY <= ballYRange / 3;
			ballZ <= ballZRange / 5;
		end if;
	end process;

end architecture;