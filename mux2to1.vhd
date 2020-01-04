----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    03:53:10 03/17/2019 
-- Design Name: 
-- Module Name:    mux2to1 - Behavioral 
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

entity mux2to1 is
    generic (   N   : integer:=128 );
    port    (
                sel : in  std_logic;
                in1 : in  std_logic_vector(N-1 downto 0);
                in2 : in  std_logic_vector(N-1 downto 0);
                output: out std_logic_vector(N-1 downto 0)
             );
end mux2to1;
architecture Behavioral of mux2to1 is
begin

with sel select
    output <= in1 when '0',
         in2 when '1',
         (others => '0')  when others;

end Behavioral;

