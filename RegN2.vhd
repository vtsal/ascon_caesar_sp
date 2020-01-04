----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    03:27:33 03/17/2019 
-- Design Name: 
-- Module Name:    RegN - Behavioral 
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

library ieee;
use ieee.std_logic_1164.all;


entity RegN is 
    generic (   N   : integer:=8 );
    port    (
                clk : in  std_logic;
                ena : in  std_logic;
                din : in  std_logic_vector(N-1 downto 0);
                dout: out std_logic_vector(N-1 downto 0)
             );
end RegN;

architecture Behavioral of RegN is 
	signal qnext:std_logic_vector(N-1 downto 0);
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
