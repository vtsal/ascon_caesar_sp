----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    03:53:58 03/17/2019 
-- Design Name: 
-- Module Name:    mux4to1 - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
entity mux8to1 is
    generic (   N   : integer:=128 );
    port    (
                sel : in  std_logic_vector(2 downto 0);
                in1 : in  std_logic_vector(N-1 downto 0);
                in2 : in  std_logic_vector(N-1 downto 0);
                in3 : in  std_logic_vector(N-1 downto 0);
                in4 : in  std_logic_vector(N-1 downto 0);
				in5 : in  std_logic_vector(N-1 downto 0);
                in6 : in  std_logic_vector(N-1 downto 0);
                in7 : in  std_logic_vector(N-1 downto 0);
                in8 : in  std_logic_vector(N-1 downto 0);
                output: out std_logic_vector(N-1 downto 0)
             );
end mux8to1;
architecture Behavioral of mux8to1 is
begin

with sel select
    output <= in1 when "000",
         in2 when "001",
         in3 when "010",
         in4 when "011",
		 in5 when "100",
         in6 when "101",
         in7 when "110",
         in8 when "111",
         (others => '0')  when others;

end Behavioral;
