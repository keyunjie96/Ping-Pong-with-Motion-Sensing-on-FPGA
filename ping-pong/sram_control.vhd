library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity sram_control is
port (
	clk: in std_logic;
	-- 对应sram
	data: inout std_logic_vector(26 downto 0);
	addr: out std_logic_vector(20 downto 0);
	RW: out std_logic_vector(1 downto 0);
	
	-- 对应内部
	in_data: out std_logic_vector(26 downto 0);
	in_addr: in std_logic_vector(18 downto 0));
end entity;

architecture behav of sram_control is
signal addr_tmp : std_logic_vector(18 downto 0);
signal data_tmp : std_logic_vector(26 downto 0);
begin
	RW <= "11";
	addr_tmp <= in_addr;
	data_tmp <= data;
	process(in_addr)
	begin
		data <= (others => 'Z');
	end process;
	
	process(clk)
	begin
		if (rising_edge(clk)) then
			addr <= "00" & addr_tmp;
			in_data <= data_tmp;
		end if;
	end process;
end architecture;