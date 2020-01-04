----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:30:58 04/18/2019 
-- Design Name: 
-- Module Name:    Reg_single_bit - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Reg_single_bit is
    port    (
                clk : in  std_logic;
                ena : in  std_logic;
                din : in  std_logic;
                dout: out std_logic
             );
end Reg_single_bit;

architecture Behavioral of Reg_single_bit is
signal qnext:std_logic;
begin	
reg: 	process(clk)
		begin
			if rising_edge(clk) then 
				if ena ='1' then
					qnext <= din; 
				end if;
			end if; 
		end process;
	  dout<=qnext;
end Behavioral;