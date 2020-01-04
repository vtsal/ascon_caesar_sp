----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:51:12 03/02/2019 
-- Design Name: 
-- Module Name:    perm - Behavioral 
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
--use ieee.numeric_std;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity perm is
	generic (N: integer:=64);
	port (
		clk	: in std_logic;
		rst	: in std_logic;
		in0, in1, in2, in3, in4  : in  std_logic_vector(N - 1 downto 0);
		out0, out1, out2, out3, out4 : out std_logic_vector(N - 1 downto 0);
		rcin	: in std_logic_vector(3 downto 0);
		done	: out std_logic;
		perm_start : in std_logic
	);
end perm;

architecture structural of perm is

type state_type is (s_reset, wait_for_perm, s_init, s_box, s_diff);
signal state, next_state : state_type:= wait_for_perm;
signal x0,x1,x2,x3,x4: std_logic_vector(N-1 downto 0);
signal x0_diff_reg,x1_diff_reg,x2_diff_reg,x3_diff_reg,x4_diff_reg: std_logic_vector(N-1 downto 0):= (others => '0');
signal load_reg_a_64, load_b_1: std_logic;
signal flag_reg, set_flag_reg, rst_flag_reg: std_logic;
signal local_count: std_logic_vector(7 downto 0);
signal x0_a, x1_a, x2_a, x3_a, x4_a: std_logic;
signal x0_b, x1_b, x2_b, x3_b, x4_b: std_logic;
signal load_a_1, load_b_64, rotate_64, load_sdiff_reg, new_in, set_new_in, rst_new_in: std_logic;
signal x0_b_64,x1_b_64,x2_b_64,x3_b_64,x4_b_64: std_logic_vector(N-1 downto 0);
signal cr: std_logic_vector(N-1 downto 0);
signal perm_start_reg, set_perm_start_reg, rst_perm_start_reg: std_logic;
signal rcin_round, rcin_reg: std_logic_vector(3 downto 0);
begin
	out0 <= x0_diff_reg;
	out1 <= x1_diff_reg;
	out2 <= x2_diff_reg;
	out3 <= x3_diff_reg;
	out4 <= x4_diff_reg;
	
	x0_b <= (x1_a and (not( x0_a xor x4_a))) xor (not(x1_a) and (x1_a xor x2_a)) xor x3_a xor x4_a xor x0_a xor x4_a;--------expression------------
	x1_b <= (x0_a xor x4_a) xor (not(x1_a) and (x1_a xor x2_a)) xor x1_a xor (x3_a and not(x1_a xor x2_a)) ;--------expression------------
	x2_b <= not( x1_a xor x2_a xor (not(x3_a) and (x3_a xor x4_a) ));--------expression------------
	x3_b <= (x1_a xor x2_a xor (not(x3_a) and (x3_a xor x4_a))) xor x3_a xor ((not(x3_a xor x4_a)) and (x0_a xor x4_a));--------expression------------
	x4_b <= (x3_a xor x4_a) xor (x1_a and (not(x0_a xor x4_a))) ;--------expression------------
------------------- DATAPATH -------------------------------------------
	data_process: process(clk)
		begin
			if rising_edge(clk) then
			if rst = '1' then
				state <= wait_for_perm;
				local_count <= x"00";
				x0 <= (others => '0');
				x1 <= (others => '0');
				x2 <= (others => '0');
				x3 <= (others => '0');
				x4 <= (others => '0');
				x0_diff_reg <= (others => '0');
				x1_diff_reg <= (others => '0');
				x2_diff_reg <= (others => '0');
				x3_diff_reg <= (others => '0');
				x4_diff_reg <= (others => '0');
				rcin_reg <= rcin;
				rcin_round <= rcin;
				state <= s_reset;
			else
			    if set_flag_reg = '1' then
		          flag_reg <= '1';
		      end if;
		      
		      if rst_flag_reg = '1' then
		          flag_reg <= '0';
		      end if;
		      
			    if set_perm_start_reg = '1' then
			         perm_start_reg <= '1';
			    end if;
			    if rst_perm_start_reg = '1' then
			         perm_start_reg <= '0';
			    end if;
			    
				if new_in = '1' then
					rcin_reg <= rcin;
					rcin_round <= rcin;
					x4 <= in4;
					local_count<= x"40";
					if(rcin_round = x"C"  and rcin_reg = x"C") then
						cr <= x"0000_0000_0000_00F0";
					elsif(rcin_round = x"8"  and rcin_reg = x"8") then
						cr <= x"0000_0000_0000_00b4";
					elsif(rcin_round = x"6"  and rcin_reg = x"6") then
						cr <= x"0000_0000_0000_0096";
					end if;
				end if;
				
				if( new_in = '1' and load_reg_a_64 = '1') then
					x0 <= in0;
					x1 <= in1;
					x2 <= in2;
					x3 <= in3;
					rcin_reg <= rcin;
					rcin_round <= rcin;
					x4 <= in4;
					local_count<= x"40";
					if(rcin_round = x"C"  and rcin_reg = x"C") then
						cr <= x"0000_0000_0000_00F0";
					elsif(rcin_round = x"8"  and rcin_reg = x"8") then
						cr <= x"0000_0000_0000_00b4";
					elsif(rcin_round = x"6"  and rcin_reg = x"6") then
						cr <= x"0000_0000_0000_0096";
					end if;
					
				elsif( load_reg_a_64 = '1' and new_in = '0') then
					x0 <= x0_diff_reg;
					x1 <= x1_diff_reg;
					x2 <= x2_diff_reg;
					x3 <= x3_diff_reg;
					x4 <= x4_diff_reg;
					local_count<= x"40";
					if(rcin_round = x"C"  and rcin_reg = x"C") then
						cr <= x"0000_0000_0000_00F0";
					elsif(rcin_round = x"8"  and rcin_reg = x"8") then
						cr <= x"0000_0000_0000_00b4";
					elsif(rcin_round = x"6"  and rcin_reg = x"6") then
						cr <= x"0000_0000_0000_0096";
					elsif(rcin_round = x"C"  and rcin_reg = x"B") then
						cr <= x"0000_0000_0000_00e1";
					elsif(rcin_round = x"C"  and rcin_reg = x"A") then
						cr <= x"0000_0000_0000_00d2";
					elsif(rcin_round = x"C"  and rcin_reg = x"9") then
						cr <= x"0000_0000_0000_00c3";
					elsif(rcin_round = x"C"  and rcin_reg = x"8") then
						cr <= x"0000_0000_0000_00b4";
					elsif((rcin_round = x"C" or rcin_round = x"8") and rcin_reg = x"7" ) then
						cr <= x"0000_0000_0000_00a5";
					elsif((rcin_round = x"C" or rcin_round = x"8") and rcin_reg = x"6" ) then
						cr <= x"0000_0000_0000_0096";
					elsif((rcin_round = x"C" or rcin_round = x"8" or rcin_round = x"6") and rcin_reg = x"5" ) then
						cr <= x"0000_0000_0000_0087";
					elsif((rcin_round = x"C" or rcin_round = x"8" or rcin_round = x"6") and rcin_reg = x"4" ) then
						cr <= x"0000_0000_0000_0078";
					elsif((rcin_round = x"C" or rcin_round = x"8" or rcin_round = x"6") and rcin_reg = x"3" ) then
						cr <= x"0000_0000_0000_0069";
					elsif((rcin_round = x"C" or rcin_round = x"8" or rcin_round = x"6") and rcin_reg = x"2" ) then
						cr <= x"0000_0000_0000_005a";
					elsif((rcin_round = x"C" or rcin_round = x"8" or rcin_round = x"6") and rcin_reg = x"1" ) then
						cr <= x"0000_0000_0000_004b";
					end if;	 		
				end if;
				
				if(load_a_1 = '1') then
					x0_a <= x0(0);
					x1_a <= x1(0);
					x2_a <= x2(0) xor cr(0);
					x3_a <= x3(0);
					x4_a <= x4(0);
				end if;
				if(load_b_64 = '1') then
					x0_b_64 <= x0_b & x0_b_64(63 downto 1); 
					x1_b_64 <= x1_b & x1_b_64(63 downto 1); 
					x2_b_64 <= x2_b & x2_b_64(63 downto 1); 
					x3_b_64 <= x3_b & x3_b_64(63 downto 1); 
					x4_b_64 <= x4_b & x4_b_64(63 downto 1); 
					local_count <= std_logic_vector(unsigned(local_count) - x"01");
				end if;
				
				if(rotate_64 = '1') then
					x0 <= '0' & x0(63 downto 1);
					x1 <= '0' & x1(63 downto 1);
					x2 <= '0' & x2(63 downto 1);
					x3 <= '0' & x3(63 downto 1);
					x4 <= '0' & x4(63 downto 1);
					cr <= '0' & cr(63 downto 1);
				end if;
				
				if(load_sdiff_reg = '1') then
					x0_diff_reg <= x0_b_64 xor x0_b_64(18 downto 0)&x0_b_64(63 downto 19) xor x0_b_64(27 downto 0)&x0_b_64(63 downto 28) ; 
					x1_diff_reg <= x1_b_64 xor x1_b_64(60 downto 0)&x1_b_64(63 downto 61) xor x1_b_64(38 downto 0)&x1_b_64(63 downto 39) ;
					x2_diff_reg <= x2_b_64 xor x2_b_64(0)&x2_b_64(63 downto 1) xor x2_b_64(5 downto 0)&x2_b_64(63 downto 6) ;
					x3_diff_reg <= x3_b_64 xor x3_b_64(9 downto 0)&x3_b_64(63 downto 10) xor x3_b_64(16 downto 0)&x3_b_64(63 downto 17) ;
					x4_diff_reg <= x4_b_64 xor x4_b_64(6 downto 0)&x4_b_64(63 downto 7) xor x4_b_64(40 downto 0)&x4_b_64(63 downto 41) ;
					rcin_reg <= std_logic_vector(unsigned(rcin_reg) - x"1");
				end if;
				
				state <= next_state;
			end if;
			end if;
		end process;
    

    
    
--------------CONTROL UNIT - FSM ----------------------------------
	state_process: process( state, perm_start, local_count,   flag_reg, rst, rcin_reg)
		begin
			load_b_1 <= '0';
			rotate_64 <= '0';
			load_sdiff_reg <= '0';
			done <= '0';
			load_reg_a_64 <= '0';
			load_a_1 <='0';
			load_b_64 <= '0';
			next_state <= s_reset;
			set_perm_start_reg <= '0';
			rst_perm_start_reg <= '0';
			set_flag_reg <= '0';
			rst_flag_reg <= '0';
			new_in <= '0'; --Change
			
			case state is
				when s_reset =>
					next_state <= wait_for_perm;
					rst_perm_start_reg <= '1';
					new_in <= '0' ;--rst_new_in <= '1';
					
				when wait_for_perm =>
					load_b_1 <= '0';
					rotate_64 <= '0';
					load_sdiff_reg <= '0';
					done <= '0';
					load_reg_a_64 <= '0';
					load_a_1 <='0';
					load_b_64 <= '0';
					load_sdiff_reg <= '0';
					next_state <= wait_for_perm;
					if perm_start = '1' and rst = '0' then
					    set_perm_start_reg <= '1';
						new_in <= '1' ;--set_new_in <= '1';
						set_flag_reg <= '1';
						next_state <= s_init;
					elsif perm_start = '0' or rst = '1' then
					    new_in <= '0' ;--rst_new_in <= '1';
						next_state <= wait_for_perm;
					end if;
			
				when s_init =>
					load_sdiff_reg <= '0';
					load_reg_a_64 <= '1';
					next_state <= s_box;
				--	new_in <= '1';
				    if flag_reg = '1' then
				        new_in <= '1';
				    end if;
				    if flag_reg = '0' then
				        new_in <= '0';
				    end if;
				    
--					if perm_start_reg = '1' and rst = '0' then
--					    --set_perm_start_reg <= '1';
--						new_in <= '1';
--						--next_state <= s_init;
--					end if;

                when s_box =>
					load_a_1 <='1';
					load_b_64 <= '1';
			        load_b_1 <= '1';
					rotate_64 <= '1';
					if( local_count = x"00") then
					    new_in <= '0';
						next_state <= s_diff;
					elsif( local_count < x"40") then
						new_in <= '0' ;--rst_new_in <= '1';
						next_state <= s_box;
					else
						new_in <= '0';
						next_state <= s_box;
					end if;
						
				when s_diff =>
					load_a_1 <='0';
					load_b_64 <= '0';
					load_b_1 <= '0';
					rotate_64 <= '0';
					load_sdiff_reg <= '1';
					new_in <= '0';
					if( rcin_reg = x"1" ) then
						done <= '1';
						next_state <= wait_for_perm;
					else
						next_state <= s_init;
						rst_flag_reg <= '1';
					end if;
					
			end case;
		end process;	
			
end structural;

