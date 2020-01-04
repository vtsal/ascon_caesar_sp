----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    04:38:36 02/05/2019 
-- Design Name: 
-- Module Name:    CipherCore - Behavioral 
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

use IEEE.NUMERIC_STD.ALL;
use work.Design_pkg.all;

entity CipherCore is
    Port ( 
            clk             : in   STD_LOGIC;
            rst             : in   STD_LOGIC;
            --PreProcessor===============================================
            ----!key----------------------------------------------------
            key             : in   STD_LOGIC_VECTOR (SW      -1 downto 0);
            key_valid       : in   STD_LOGIC;
            key_ready       : out  STD_LOGIC;
            ----!Data----------------------------------------------------
            bdi             : in   STD_LOGIC_VECTOR (W       -1 downto 0);
            bdi_valid       : in   STD_LOGIC;
            bdi_ready       : out  STD_LOGIC;
            bdi_partial     : in   STD_LOGIC;
            bdi_pad_loc     : in   STD_LOGIC_VECTOR (Wdiv8   -1 downto 0);
            bdi_valid_bytes : in   STD_LOGIC_VECTOR (Wdiv8   -1 downto 0);
            bdi_size        : in   STD_LOGIC_VECTOR (3       -1 downto 0);
            bdi_eot         : in   STD_LOGIC;
            bdi_eoi         : in   STD_LOGIC;
            bdi_type        : in   STD_LOGIC_VECTOR (4       -1 downto 0);
            decrypt_in      : in   STD_LOGIC;
            key_update      : in   STD_LOGIC;
            --!Post Processor=========================================
            bdo             : out  STD_LOGIC_VECTOR (W       -1 downto 0);
            bdo_valid       : out  STD_LOGIC;
            bdo_ready       : in   STD_LOGIC;
            --bdo_size        : out  STD_LOGIC_VECTOR (3 -1 downto 0);
            bdo_type        : out  STD_LOGIC_VECTOR (4       -1 downto 0);
            bdo_valid_bytes : out  STD_LOGIC_VECTOR (Wdiv8   -1 downto 0);
            end_of_block    : out  STD_LOGIC;
            decrypt_out     : out  STD_LOGIC;
            msg_auth        : out std_logic;
            msg_auth_valid  : out std_logic;
            msg_auth_ready  : in  std_logic
         );
            
end CipherCore;

architecture structure of CipherCore is
	
	constant HDR_DATA: std_logic_vector(3 downto 0) := x"4";
	constant HDR_NPUB: std_logic_vector(3 downto 0) := x"D";
	constant HDR_AD: std_logic_vector(3 downto 0) := x"1";
	type fsm_state is (S_RESET, WAIT_KEY, LOAD_KEY,WAIT_NPUB,LOAD_NPUB, UPD_PERM_1, PERM_INIT, UPD_KEY_REG, WAIT_AD, LOAD_AD, UPD_PERM_AD, PERM_AD, UPD_KEY_NONCE2, 
						WAIT_PT, LOAD_1_0_C, LOAD_1_0_D, LOAD_1_0_E, LOAD_PT, OUTPUT_CT, UPD_PERM_PT, PERM_PT, PERM_FINAL_LOAD, LOAD_OUTPUT_CT, PERM_FINAL, LOAD_TAG, LOAD_TAG_1, LOAD_TAG_2, 
						OUTPUT_TAG_1, OUTPUT_TAG_2, LOAD_STATUS_MSG, PAD_AD_FINAL, LOAD_TAG_STORE, PAD_PT_FINAL, CORNER, OUTPUT_STATUS_MSG, COMPARE_TAG);
   signal state, next_state : fsm_state;
   
	signal bdi_mux_1_sel :std_logic_vector(1 downto 0) := "00";
	signal nonce_mux_sel:std_logic_vector(2 downto 0) := "000";
	signal bdi_reg_en, bdi_reg_1_en, bdi_reg_2_en, data_reg_en :std_logic := '0';
	signal bdi_mux_2_sel :std_logic_vector(1 downto 0);
    signal enc_dec_sel, output_reg_en, perm_start, rst_count_key :std_logic; 
	signal enc_dec_2_sel: std_logic_vector(2 downto 0);
	signal key_reg_1_en, key_reg_2_en, key_mux_sel, key_reg_en, nonce_reg_en, tag_reg_en, tag_reg_1_en, tag_reg_2_en :std_logic; 
	signal rcin	:std_logic_vector(3 downto 0);
	signal set_rcin_to_c, set_rcin_to_6 :std_logic;
	signal set_perm_start, rst_perm_start :std_logic;
	signal rst_count_num, rst_ad_first, set_ad_first, eot_reg, rst_eot_reg, set_eot_reg: std_logic:= '0';
	signal ad_first: std_logic:= '1'; 
	signal set_ad_pad_first,ad_pad_first,rst_ad_pad_first: std_logic:= '0';
	signal pt_first: std_logic:= '1'; 
	signal tag_store_reg_out: std_logic_vector(127 downto 0);
	signal tag_store_reg_en: std_logic:= '0';
	signal rot_count: std_logic_vector(2 downto 0);
	signal inc_rot_count, rst_rot_count: std_logic;
	
	
	signal set_decrypt_reg, rst_decrypt_reg, decrypt_reg: std_logic;
	signal set_no_pt, rst_no_pt, no_pt: std_logic;
	signal set_no_ad, rst_no_ad, no_ad: std_logic;
	signal set_no_data, rst_no_data, no_data: std_logic;
	signal eoi_reg, set_eoi_reg, rst_eoi_reg: std_logic;
	signal output_reg_xor_1, set_output_reg_xor_1, rst_output_reg_xor_1: std_logic; 
	signal rst_first_perm, set_first_perm, first_perm: std_logic;
	signal first_perm_pt, set_first_perm_pt, rst_first_perm_pt: std_logic;
	signal rst_count_out, inc_pt_size, perm_rst, set_ad_perm_first, ad_perm_first,set_pt_size_to_1, rst_pt_size, rst_ad_perm_first: std_logic:='0';
	signal no_ct, rst_no_ct, set_no_ct, from_wait_pt, rst_from_wait_pt, set_from_wait_pt: std_logic:= '0';		
	signal set_pt_pad_first,pt_pad_first,rst_pt_pad_first: std_logic:= '0';
	signal set_pt_first,rst_pt_first,pt_size_1, set_pt_size_1, rst_pt_size_1: std_logic:= '0';
	signal bdi_mux_out, bdi_reg_1_out, key_reg_1_out: std_logic_vector(7 downto 0);
	signal x0_out, bdi_mux_2_out, data_reg_out, data_mux_2_out, tag_reg_1_out, tag_reg_2_out: std_logic_vector(63 downto 0);
	signal x0_in, data_xor_out, x1_out, x2_out,x3_out, x4_out, output_reg_out:std_logic_vector(63 downto 0);
	signal bdi_reg_2_out: std_logic_vector(127 downto 0) := (others => '0');
	signal key_reg_2_out, key_mux_out, key_reg_out, key_xor_out:std_logic_vector(127 downto 0);
	signal nonce_mux_out, nonce_reg_out, nonce_xor_out, tag_xor_out: std_logic_vector(127 downto 0);
	signal count_key, count_npub :std_logic_vector(4 downto 0):= "00000";
	signal count_tag_out: std_logic_vector(3 downto 0):= "0000";
	signal inc_count_tag, rst_count_tag, inc_out_size, set_out_size_count_num, data_reg_xor: std_logic;
	signal pt_size: std_logic_vector(3 downto 0):= "0000";
	signal count_num, count_out, ad_size, out_size :std_logic_vector(2 downto 0):="000";
	signal rst_ad_size, inc_ad_size :std_logic ;
	signal inc_count_key, inc_count_npub, rst_count_npub, perm_done, inc_count_num, output_data, inc_count_out:std_logic:='0';
	signal bdo_reg_en, bdo_valid_d, bdo_valid_en, bdo_valid_bytes_en, end_of_block_d, end_of_block_en, bdo_type_en: std_logic:= '0';
	signal bdo_valid_bytes_d: std_logic_vector(0 downto 0);
	signal bdo_type_d: std_logic_vector(3 downto 0);
begin

	bdi_mux_1:
	entity work.mux4to1(Behavioral) 
   generic map(   N	=>	8 )
	port map(
		in1	=>		bdi,
		in2	=>		x"80",
		in3	=>		x"00",
		in4	=>		x"00",
		sel	=>		bdi_mux_1_sel,
		output=>	bdi_mux_out	
	);

	bdi_reg_1:
	entity work.RegN(Behavioral)
   generic map(   N	=>	8 )
	port map(
		clk	=>		clk,
		ena	=>		bdi_reg_1_en,
		din	=>		bdi_mux_out,
		dout=>		bdi_reg_1_out
	);
	
	bdi_reg_2:
	entity work.RegN(Behavioral)
	generic map(	N	=> 128)
	port map(
		clk	=>	clk,
		ena	=>	bdi_reg_2_en,
		din	=>	bdi_reg_2_out(119 downto 0) & bdi_reg_1_out,
		dout	=> bdi_reg_2_out
	);
	
	bdi_mux_2:
	entity work.mux4to1(Behavioral)
    generic map(   N	=>	64 )
	port map(
		in1	=>		bdi_reg_2_out(63 downto 0),
		in2	=>		x"8040_0c06_0000_0000",
		in3	=> 	    data_reg_out xor output_reg_out,
		in4	=>		x"8000_0000_0000_0000",
		sel	=>		bdi_mux_2_sel,
		output=>	bdi_mux_2_out	
	);

	data_reg:
	entity work.RegN(Behavioral)
	generic map(	N	=> 64)
	port map(
		clk	=>	clk,
		ena	=>	data_reg_en,
		din	=>	bdi_mux_2_out,
		dout=>  data_reg_out
	);
	
	data_xor_out <= data_reg_out xor x0_out;
	
	data_mux:
	entity work.mux2to1(Behavioral)
    generic map(   N	=>	64 )
	port map(
		in1	=>		data_xor_out,
		in2	=>		data_reg_out,
		sel	=>		enc_dec_sel,
		output=>	x0_in	
	);

	key_reg_1:
	entity work.RegN(Behavioral)
	generic map(	N	=> 8)
	port map(
		clk	=>	clk,
		ena	=>	key_reg_1_en,
		din	=>	key,
		dout=>  key_reg_1_out
	);
	
	key_reg_2:
	entity work.RegN(Behavioral) 
	generic map(	N	=> 128)
	port map(
		clk	=>	clk,
		ena	=>	key_reg_2_en,
		din	=>	key_reg_2_out(119 downto 0) & key_reg_1_out,
		dout=>  key_reg_2_out
	);
	
	key_mux: 
	entity work.mux2to1(Behavioral)
    generic map(   N	=>	128 )
	port map(
		in1	=>		key_reg_2_out,
		in2	=>		x"0000_0000_0000_0000_0000_0000_0000_0000",
		sel	=>		key_mux_sel,
		output=>	key_mux_out	
	);
	
	key_reg:
	entity work.RegN(Behavioral)
	generic map(	N	=> 128)
	port map(
		clk	=>	clk,
		ena	=>	key_reg_en,
		din	=>	key_mux_out,
		dout=>  key_reg_out
	);
		
	key_xor_out <= (x1_out & x2_out) xor key_reg_out;
	
	nonce_mux:
	entity work.mux8to1(Behavioral)
   generic map(   N	=>	128 )
	port map(
		in1	=>		bdi_reg_2_out,
		in2	=>		key_reg_2_out,
		in3	=>		x"0000_0000_0000_0000_0000_0000_0000_0000",
		in4	=>		x"0000_0000_0000_0000_0000_0000_0000_0001",
		in5	=> 	    key_reg_2_out xor x"0000_0000_0000_0000_0000_0000_0000_0001",
		in6 =>		bdi_reg_2_out,
		in7 =>		bdi_reg_2_out,
		in8 =>		bdi_reg_2_out,
		sel	=>		nonce_mux_sel,
		output=>	nonce_mux_out	
	);
	
	nonce_reg:
	entity work.RegN(Behavioral)
	generic map(	N	=> 128)
	port map(
		clk	=>	clk,
		ena	=>	nonce_reg_en,
		din	=>	nonce_mux_out,
		dout=>  nonce_reg_out
	);
	
	nonce_xor_out <= (x3_out & x4_out) xor nonce_reg_out;
	
	permutation_block:
	entity work.perm(structural)
	port map(
		clk	=>		clk,
		rst	=>		perm_rst,
		in0	=>		x0_in,
		in1	=>		key_xor_out(127 downto 64),
		in2	=>		key_xor_out(63 downto 0),
		in3	=>		nonce_xor_out(127 downto 64),
		in4	=>		nonce_xor_out(63 downto 0),
		out0	=>		x0_out,
		out1	=>		x1_out,
		out2	=>		x2_out,
		out3	=>		x3_out,
		out4	=>		x4_out,
		perm_start	=>	perm_start,
		rcin	=>		rcin,
		done => 		perm_done
	);
	
	data_mux_2:
	entity work.mux8to1(Behavioral)
	generic map( N => 64)
	port map(
		in1	=>		x0_out,
		in2	=>		x0_in,
		in3	=>		output_reg_out(55 downto 0) & "00000000",
		in4	=>		tag_reg_1_out,
		in5	=>		tag_reg_2_out,
		in6	=>		"00000000" & output_reg_out(63 downto 8),
		in7	=>		output_reg_out xor x"8000_0000_0000_0000",
		in8	=>		x0_in,
		sel	=>		enc_dec_2_sel,
		output =>   data_mux_2_out
	);
	
	output_reg:
	entity work.RegN(Behavioral)
	generic map( N	=>	64	)
	port map(
		clk	=>	clk,
		ena	=>	output_reg_en,
		din	=>	data_mux_2_out,
		dout=>	output_reg_out
	);
	
	tag_xor_out <= (x3_out	&	x4_out) xor	key_reg_2_out;
	
	tag_reg1:
	entity work.RegN(Behavioral)
	generic map( N	=>	64	)
	port map(
		clk	=>	clk,
		ena	=>	tag_reg_1_en,
		din	=>	tag_xor_out(127 downto 64),
		dout=>	tag_reg_1_out
	);	
	
	tag_reg2:
	entity work.RegN(Behavioral)
	generic map( N	=>	64	)
	port map(
		clk	=>	clk,
		ena	=>	tag_reg_2_en,
		din	=>	tag_xor_out(63 downto 0),
		dout=>	tag_reg_2_out
	);	
	
	bdo_reg:
	entity work.RegN(Behavioral)
	generic map( N	=>	8	)
	port map(
		clk	=>	clk,
		ena	=>	bdo_reg_en,
		din	=>	output_reg_out(63 downto 56),
		dout=>	bdo
	);	
	
	bdo_type_reg:
	entity work.RegN(Behavioral)
	generic map( N	=>	4	)
	port map(
		clk	=>	clk,
		ena	=>	bdo_type_en,
		din	=>	bdo_type_d,
		dout=>	bdo_type
	);	
	
	bdo_valid_reg:
	entity work.Reg_single_bit(Behavioral)
	port map(
		clk	=>	clk,
		ena	=>	bdo_valid_en,
		din	=>	bdo_valid_d,
		dout=>	bdo_valid
	);	
	
	bdo_valid_bytes_reg:
	entity work.RegN(Behavioral)
	generic map( N	=>	1	)
	port map(
		clk	=>	clk,
		ena	=>	bdo_valid_bytes_en,
		din	=>	bdo_valid_bytes_d,
		dout=>	bdo_valid_bytes
	);	

	tag_store_reg:
	entity work.RegN(Behavioral)
	generic map( N	=>	128	)
	port map(
		clk	=>	clk,
		ena	=>	tag_store_reg_en,
		din	=>	tag_store_reg_out(119 downto 0) & bdi,
		dout	=>	tag_store_reg_out
	);	

	end_of_block_reg:
	entity work.Reg_single_bit(Behavioral)
	port map(
		clk	=>	clk,
		ena	=>	end_of_block_en,
		din	=>	end_of_block_d,
		dout=>	end_of_block
	);		

----------------------CONTROL PATH------------------------------

	sync: process(rst, clk)
	begin
		if rst = '1' then
			state <= S_RESET;
		else
		if rising_edge(clk) then
		    
		    if set_rcin_to_c = '1' then --
		      rcin <= x"C";
		    end if;
		    
		    if set_rcin_to_6 = '1' then --
		      rcin <= x"6";
		    end if;
		    
		    if rst_from_wait_pt = '1' then
		      from_wait_pt <= '0';
		    end if;
		    
		    if set_from_wait_pt = '1' then
		      from_wait_pt <= '1';
		    end if;
		      
			if rst_ad_size = '1' then
			    ad_size <= (others => '0');
			end if;
			
			if inc_ad_size = '1' then
			    ad_size <= std_logic_vector( unsigned(count_num) + "001");
			end if;
			
			if	rst_pt_size_1 = '1' then
				pt_size_1 <= '0';
			end if;
			
			if	set_pt_size_1 = '1' then
				pt_size_1 <= '1';
			end if;
						
			if rst_ad_first = '1' then
				ad_first <= '0';
			end if;
			
			if set_ad_first = '1' then
				ad_first <= '1';
			end if;
			
			if rst_pt_first = '1' then
				pt_first <= '0';
			end if;
			
			if set_pt_first = '1' then
				pt_first <= '1';
			end if;
			
			if set_eot_reg = '1' then
				eot_reg <= '1';
			end if;
			
			if rst_eot_reg = '1' then
				eot_reg <= '0';
			end if;
			
			if set_ad_pad_first = '1' then
				ad_pad_first <= '1';
			end if;
			
			if rst_ad_pad_first = '1' then
				ad_pad_first <= '0';
			end if;
			
			if set_pt_pad_first = '1' then
				pt_pad_first <= '1';
			end if;
			
			if rst_pt_pad_first = '1' then
				pt_pad_first <= '0';
			end if;
			
			if rst_count_key = '1' then
				count_key <= "00000";
			end if;
			
			if inc_count_key = '1' then
				count_key <= std_logic_vector(unsigned(count_key) + "00001");
			end if;
			
			if rst_rot_count = '1' then
				rot_count <= "000";
			end if;
			
			if inc_rot_count = '1' then
				rot_count <= std_logic_vector(unsigned(rot_count) + "001");
			end if;
			
			if rst_pt_size = '1' then
				pt_size <= "0000";
			end if;
			
			if set_pt_size_to_1 = '1' then
				pt_size <= "0001";
			end if;
			
			if inc_pt_size = '1' then
				pt_size <= std_logic_vector( unsigned(pt_size) + "0001");
			end if;
			
			if inc_out_size = '1' then
				out_size <= std_logic_vector( unsigned(out_size) + "001");
			end if;
						
			if rst_count_tag = '1' then
				count_tag_out <= "0000";
			end if;
			
			if set_out_size_count_num = '1' then
				out_size <= count_num;
			end if;
			
			if rst_first_perm = '1' then
				first_perm <= '0';
			end if;
			
			if set_first_perm = '1' then
				first_perm <= '1';
			end if;
			
			if inc_count_tag = '1' then
				count_tag_out <= std_logic_vector(unsigned(count_tag_out) + "0001");
			end if;
			
			if inc_count_out = '1' then
				count_out <= std_logic_vector(unsigned(count_out) + "001");
			end if;
			
			if rst_count_npub = '1' then
				count_npub <= "00000";
			end if;
			
			if inc_count_npub = '1' then
				count_npub <= std_logic_vector(unsigned(count_npub) + "00001");
			end if;
			
			if rst_count_num = '1' then
				count_num <= "000";
			end if;
			
			if inc_count_num = '1' then
				count_num <= std_logic_vector(unsigned(count_num) + "001");
			end if;
					
			if rst_ad_perm_first = '1' then
				ad_perm_first <= '0';
			end if;
			
			if set_ad_perm_first = '1' then
				ad_perm_first <= '1';
			end if;
			
			if rst_no_ct = '1' then
				no_ct <= '0';
			end if;
			
			if set_no_ct = '1' then
				no_ct <= '1';
			end if;
			
			if rst_no_pt = '1' then
				no_pt <= '0';
			end if;
			
			if set_no_pt = '1' then
				no_pt <= '1';
			end if;
			
			if rst_no_ad = '1' then
				no_ad <= '0';
			end if;
			
			if set_no_ad = '1' then
				no_ad <= '1';
			end if;
			
			if rst_first_perm_pt = '1' then
				 first_perm_pt <= '0';
			end if;
			
			if set_first_perm_pt = '1' then
				first_perm_pt <= '1';
			end if;
			
			if rst_count_out = '1' then
				count_out <= "000";
			end if;
			
			if set_output_reg_xor_1 = '1' then
				output_reg_xor_1 <= '1';
			end if;
			
			if rst_eoi_reg = '1' then
				eoi_reg <= '0';
			end if;
			
			if set_eoi_reg = '1' then
				eoi_reg <= '1';
			end if;
			
			if rst_no_data = '1' then
				no_data <= '0';
			end if;
			
			if set_no_data = '1' then
				no_data <= '1';
			end if;
			
			if rst_output_reg_xor_1 = '1' then
				output_reg_xor_1 <= '0';
			end if;
						
			if set_perm_start = '1' then
				perm_start <= '1';
			end if;
			if rst_perm_start = '1' then
				perm_start <= '0';
			end if;			

			if set_decrypt_reg = '1' then
				decrypt_reg <= '1';
			end if;
			
			if rst_decrypt_reg = '1' then
				decrypt_reg <= '0';
			end if;	

			state <= next_state;
		end if;
		end if; 
	end process;
		
	controller: process(  state, count_key, output_reg_xor_1, no_data, count_npub, perm_done, bdi_valid, bdi_type, bdi_eot, bdi_eoi, count_num, key_valid, key_update, count_tag_out, rot_count, count_out)
	begin
	next_state <= S_RESET;
	bdi_mux_1_sel <= (others => '0');
	bdi_reg_1_en <= '0';
	bdi_reg_2_en <= '0';
	bdi_mux_2_sel <= "00";
	data_reg_en	<= '0';
	tag_store_reg_en <= '0';
	enc_dec_sel <= '0';
	enc_dec_2_sel <= "000";
	output_reg_en <= '0';
	key_reg_1_en <= '0'; 
	key_reg_2_en <= '0';
	key_reg_en	<= '0';
	key_mux_sel <= '0';
	nonce_mux_sel <= (others => '0'); 
	nonce_reg_en <= '0';
	tag_reg_1_en <= '0';
	tag_reg_2_en <= '0';
	set_perm_start <= '0';
	rst_perm_start <= '0';
	rst_count_key<= '0';
	inc_count_key<= '0';
	inc_count_npub<= '0';
	rst_count_npub<= '0';
	set_pt_size_to_1 <= '0';
	key_ready <= '0';
	bdi_ready <= '0';
	set_ad_pad_first <= '0';
	rst_ad_pad_first <= '0';
	msg_auth <= '0';
	msg_auth_valid <= '0';
	rst_rot_count <= '0';
	inc_rot_count <= '0';
	inc_pt_size <= '0';
	rst_pt_size <= '0';
	bdo_valid_d <= '0';
	bdo_valid_en <= '1';
	bdo_valid_bytes_d <= "0";
	bdo_valid_bytes_en <= '1';
	end_of_block_d <= '0';
	end_of_block_en <= '1';
	bdo_reg_en <= '0';
	perm_rst <= '0';
	rst_count_tag <= '0';
	inc_count_tag <= '0';
	set_no_ct <= '0';
	rst_no_ct <= '0';
	set_ad_first <= '0';
	rst_ad_first <= '0';
    inc_count_out <= '0';
	rst_count_out <= '0';
	set_pt_pad_first <= '0';
	rst_pt_pad_first <= '0';
	rst_ad_perm_first <= '0';
	set_ad_perm_first <= '0';
	set_pt_first <= '0';
	rst_pt_first <= '0';
	set_no_data <= '0';
	rst_no_data <= '0';
	set_first_perm <= '0';
	rst_first_perm <= '0';
	set_eoi_reg <= '0';
	rst_eoi_reg <= '0';
	data_reg_xor <= '0';
	set_first_perm_pt <= '0';
	rst_first_perm_pt <= '0';
	set_output_reg_xor_1 <= '0';
	rst_output_reg_xor_1 <= '0';
	inc_count_num <= '0';
	rst_count_num <= '0';
	set_out_size_count_num <= '0';
	inc_out_size <= '0';
	rst_pt_size_1 <= '0';
	set_pt_size_1 <= '0';
	rst_no_ad <= '0';
	set_no_ad <= '0';
	set_eot_reg <= '0';
	rst_eot_reg <= '0';
	rst_no_pt <= '0';
	set_no_pt <= '0';
	rst_decrypt_reg <= '0';
	set_decrypt_reg <= '0';
	inc_ad_size <= '0';
	rst_ad_size <= '0';
	rst_from_wait_pt <= '0';
	set_from_wait_pt <= '0';
	set_rcin_to_c <= '0';
	set_rcin_to_6 <= '0';
	bdo_type_en <= '0';
	bdo_type_d <= (others => '0');
	--ad_size <= (others => '0');
	case state is
	
	when S_RESET =>
	    rst_ad_size <= '1';
		perm_rst <= '1';
		set_pt_size_1 <= '1';
		set_ad_perm_first <= '1';
		set_ad_first <= '1';
		rst_ad_pad_first <= '1';
		rst_eot_reg <= '1';
		rst_count_npub <= '1';
		rst_count_key <= '1';
		rst_from_wait_pt <= '1';--from_wait_pt <= '0';
		rst_no_ct <= '1';
		set_pt_first <= '1';
		--ad_size <= (others => '0');
		rst_eoi_reg <= '1';
		rst_pt_size <= '1';
		rst_no_data <= '1';
		rst_no_ad <= '1';
		rst_rot_count <= '1';
		set_output_reg_xor_1 <= '1';
		set_first_perm_pt <= '1';
		set_first_perm <= '1';
		rst_no_pt <= '1';
		if decrypt_in = '1' then
			set_decrypt_reg <= '1';
		elsif decrypt_in = '0' then
			rst_decrypt_reg <= '1';
		end if;
		next_state <= WAIT_KEY;
	
	when WAIT_KEY =>
		if decrypt_in = '1' then
			set_decrypt_reg <= '1';
		elsif decrypt_in = '0' then
			rst_decrypt_reg <= '1';
		end if;
		if key_valid = '1' and key_update = '1' then
			next_state <= LOAD_KEY;
		elsif bdi_valid = '1' and bdi_type = HDR_NPUB then
			next_state <= LOAD_NPUB;
		else
			next_state <= WAIT_KEY;
		end if;
	
	when LOAD_KEY =>
		if decrypt_in = '1' then
			set_decrypt_reg <= '1';
		elsif decrypt_in = '0' then
			rst_decrypt_reg <= '1';
		end if;
		key_ready <= '1';
		key_reg_1_en <= '1';
		key_reg_2_en <= '1';
		inc_count_key <= '1';
		if count_key = "10000" then
			next_state <= WAIT_NPUB;
		else
			next_state <= LOAD_KEY;
		end if;
	
	when WAIT_NPUB =>
		if decrypt_in = '1' then
			set_decrypt_reg <= '1';
		elsif decrypt_in = '0' then
			rst_decrypt_reg <= '1';
		end if;
		rst_count_key <= '1';
		if bdi_valid = '1' and bdi_type = HDR_NPUB then 
			next_state <= LOAD_NPUB;
		else
			next_state <= WAIT_NPUB;
		end if;
	
	when LOAD_NPUB =>
		if decrypt_in = '1' then
			set_decrypt_reg <= '1';
		elsif decrypt_in = '0' then
			rst_decrypt_reg <= '1';
		end if;
		inc_count_npub <= '1';
		bdi_ready <= '1';
		bdi_mux_1_sel <= (others => '0');
		bdi_reg_1_en <= '1';
		bdi_reg_2_en <= '1';
		if bdi_eoi = '1' then
			set_eoi_reg <= '1';
			set_no_data <= '1';
		end if;
				
		if  count_npub = "10000" then
			next_state <= UPD_PERM_1;
		else
			next_state <= LOAD_NPUB;
		end if;
		
	when UPD_PERM_1 =>
		bdi_mux_2_sel <= "01";
		data_reg_en <= '1';
		key_mux_sel <= '0';
		key_reg_en <= '1';
		nonce_mux_sel <= (others => '0');
		nonce_reg_en <= '1';
		enc_dec_sel <= '0';
		enc_dec_2_sel <= "000";
		set_perm_start <= '1';
		set_rcin_to_c <= '1'; --rcin<= x"C";
		next_state <= PERM_INIT;
		
	when PERM_INIT =>	
		if bdi_type = "0100" then
			set_no_ad <= '1';
		end if;	
		rst_perm_start <= '1';
		if perm_done = '1' then 
			next_state <= UPD_KEY_REG;
		else
			next_state <= PERM_INIT;
		end if;
	
	when UPD_KEY_REG =>
		key_mux_sel <= '1';
		key_reg_en <= '1';
		nonce_mux_sel <= "001";
		nonce_reg_en <= '1';
		next_state <= WAIT_AD;
		
	when WAIT_AD =>
		if eoi_reg = '1' then
			bdi_mux_1_sel <= "01";
			bdi_reg_1_en <= '1';
			next_state <= PAD_PT_FINAL;
		elsif bdi_type = "0100" and eoi_reg = '0' and ad_first = '1' then
			set_no_data <= '1';
			next_state <= UPD_KEY_NONCE2;
		else
			if bdi_valid = '1' and bdi_type = HDR_AD then
				if bdi_eoi = '1' and bdi_type = "0001" then
					set_no_pt <= '1';
				end if;
				bdi_ready <= '1';
				bdi_mux_1_sel <= (others => '0');
				bdi_reg_1_en <= '1';
				if ad_first = '1' then
					rst_ad_first <= '1';
				else
					inc_count_num <= '1';
					bdi_reg_2_en <= '1';
				end if;
				
				if bdi_eot = '1' then
					set_ad_pad_first <= '1';
					set_eot_reg <= '1';
					next_state <= LOAD_1_0_D;
				else
					next_state <= LOAD_AD;
				end if;
			elsif bdi_type = "0100" or bdi_type = "0000" then	
				set_eot_reg <= '1';			
				bdi_mux_1_sel <= "01";
				bdi_reg_1_en <= '1';
				bdi_reg_2_en <= '1';
				rst_count_num <= '1';
				inc_count_num <= '1';
				next_state <= PAD_AD_FINAL;
			else
				next_state <= WAIT_AD;
			end if;
		end if;
	
	when LOAD_AD =>
		bdi_ready <= '1';
		bdi_mux_1_sel <= (others => '0');
		bdi_reg_1_en <= '1';
		bdi_reg_2_en <= '1';
		inc_count_num <= '1';
		if bdi_eot = '1' and bdi_eoi = '1' then
			set_no_pt <= '1';
		end if;	
		if bdi_eot = '1' then
			if count_num = "111" then
				next_state <= UPD_PERM_AD;
			else
				set_ad_pad_first <= '1';
				set_eot_reg <= '1';
				inc_ad_size <= '1';--ad_size <= std_logic_vector( unsigned(count_num) + "001");
				next_state <= LOAD_1_0_D;
			end if;
		else 
			if count_num = "111" then
				next_state <= UPD_PERM_AD;
			else
				next_state <= LOAD_AD;
			end if;
		end if;
	
	when PAD_AD_FINAL =>
		bdi_mux_1_sel <= "11";
		bdi_reg_1_en <= '1';
		bdi_reg_2_en <= '1';
		if count_num = "111" then
			rst_count_num <= '1';
			next_state <= UPD_PERM_AD;
		else
			inc_count_num <= '1';
			next_state <= PAD_AD_FINAL;
		end if;
	
	when LOAD_1_0_D =>
		bdi_reg_1_en <= '1';
		bdi_reg_2_en <= '1';
		inc_count_num <= '1';
		if bdi_eot = '1' then
			set_eot_reg <= '1';
		end if;
		if ad_pad_first = '1' then
			bdi_mux_1_sel <= "01";
			rst_ad_pad_first <= '1';
		else 
			bdi_mux_1_sel <= "10";
		end if;
		if count_num = "111" then
			next_state <= UPD_PERM_AD;
		else
			next_state <= LOAD_1_0_D;
		end if;

	when UPD_PERM_AD =>
		bdi_mux_2_sel <= "00";
		key_mux_sel <= '1';
		data_reg_en <= '1';
		enc_dec_sel <= '0';
		if ad_perm_first = '1' then
			rst_ad_perm_first <= '1';
		else
			nonce_reg_en <= '1';
			nonce_mux_sel <= "010";
		end if;
		set_perm_start <= '1';
		set_rcin_to_6 <= '1'; --rcin <= x"6";
		next_state <= PERM_AD;
		
	when PERM_AD =>
		rst_perm_start <= '1';
		if perm_done = '1' then
			if eot_reg = '1' and ad_size = "111" then
				rst_ad_size <= '1'; --ad_size <= "000";
				bdi_mux_1_sel <= "01";
				bdi_reg_1_en <= '1';
				rst_count_num <= '1';
				next_state <= PAD_AD_FINAL;	
			elsif eot_reg = '1' then
				next_state <= UPD_KEY_NONCE2;
			else 
				next_state <= WAIT_AD;
			end if;
		else
			next_state <= PERM_AD;
		end if;
		
	when UPD_KEY_NONCE2 =>
		rst_eot_reg <= '1';
		key_mux_sel <= '1';
		key_reg_en <= '1';
		nonce_mux_sel <= "011";
		nonce_reg_en <= '1';
		next_state <= WAIT_PT;
		
	when WAIT_PT =>
		if no_pt = '1' and pt_first = '1' then
			next_state <= PAD_PT_FINAL;
			if decrypt_reg = '1' then 
					bdi_mux_1_sel <= "11";
			else
					bdi_mux_1_sel <= "01";
			end if;
			bdi_reg_1_en <= '1';
			bdi_reg_2_en <= '1';
			rst_count_num <= '1';
			set_from_wait_pt <= '1';
			inc_out_size <= '1';
			set_no_ct <= '1';
			rst_pt_size <= '1';
		else
			if bdi_valid = '1' and bdi_type = HDR_DATA then
				bdi_ready <= '1';
				bdi_mux_1_sel <= (others => '0');
				bdi_reg_1_en <= '1';
				if pt_first = '1' then
					rst_pt_first <= '1';
				else
					inc_count_num <= '1';
					bdi_reg_2_en <= '1';
				end if;			
				if bdi_eot = '1' then
					set_pt_pad_first <= '1';
					set_out_size_count_num <= '1';
					set_eot_reg <= '1';
					rst_pt_size <= '1';
					next_state <= LOAD_1_0_C;
				else
					rst_pt_size <= '1';
					if pt_size_1 = '0' then set_pt_size_to_1 <= '1'; end if;
					next_state <= LOAD_PT;
				end if;
			elsif bdi_type = "0000" or bdi_type = "1101" or (decrypt_reg = '1' and ( bdi_type = "1000" or bdi_type = "1101" )) then --and decrypt_in = '0' then ----------DECRYPTION	
				set_eot_reg <= '1';		
				if decrypt_reg = '1' then 
					bdi_mux_1_sel <= "11";
				else
					bdi_mux_1_sel <= "01";
				end if;
				bdi_reg_1_en <= '1';
				bdi_reg_2_en <= '1';
				rst_count_num <= '1';
				inc_count_num <= '1';
				set_from_wait_pt <= '1';
				inc_out_size <= '1';
				rst_pt_size <= '1';
				next_state <= PAD_PT_FINAL;
			else
				next_state <= WAIT_PT;
			end if;
		end if;
			
	when LOAD_PT =>
		bdi_ready <= '1';
		bdi_mux_1_sel <= (others => '0');
		bdi_reg_1_en <= '1';
		bdi_reg_2_en <= '1';
		inc_count_num <= '1';if bdi_eot = '1' then
			if count_num = "111" then
				next_state <= UPD_PERM_PT;
			else
			set_pt_pad_first <= '1';
			set_eot_reg <= '1';
			inc_pt_size <= '1';
			set_out_size_count_num <= '1';
			next_state <= LOAD_1_0_C;
			end if;
		else 
			inc_pt_size <= '1'; 
			if count_num = "111" then
				next_state <= UPD_PERM_PT;
			else
				next_state <= LOAD_PT;
			end if;
		end if;

	when PAD_PT_FINAL =>
		bdi_mux_1_sel <= "11";
		bdi_reg_1_en <= '1';
		bdi_reg_2_en <= '1';
		if count_num = "111" then
			rst_count_num <= '1';
			set_no_ct <= '1';
			next_state <= UPD_PERM_PT;
		else
			inc_count_num <= '1';
			next_state <= PAD_PT_FINAL;
		end if;
	
	when LOAD_1_0_C =>
		bdi_reg_1_en <= '1';
		bdi_reg_2_en <= '1';
		inc_count_num <= '1';
		if pt_pad_first = '1' then
			inc_pt_size <= '1';
			if decrypt_reg = '1' then
				bdi_mux_1_sel <= "11";
			else
				bdi_mux_1_sel <= "01";
			end if;
			set_out_size_count_num <= '1';
			rst_pt_pad_first <= '1';
		else 
			bdi_mux_1_sel <= "10";
		end if;
		if count_num = "111" then
			next_state <= UPD_PERM_PT;
		else
			next_state <= LOAD_1_0_C;
		end if;
	
	when UPD_PERM_PT =>
		bdi_mux_2_sel <= "00";
		data_reg_en <= '1';
		enc_dec_sel <= '0';
		if first_perm_pt = '0' then
			nonce_mux_sel <= "010";
			nonce_reg_en <= '1';
		end if;
		if no_ad = '1' and first_perm_pt = '1' then
			nonce_mux_sel <= "100";
			nonce_reg_en <= '1';
		end if;
		if no_pt = '1' then
			next_state <= PERM_FINAL_LOAD;
		elsif no_ct = '1' and from_wait_pt = '0' then
			next_state <= PERM_FINAL_LOAD;
		else
			next_state <= LOAD_OUTPUT_CT;
		end if;
	
	when LOAD_OUTPUT_CT =>
		enc_dec_2_sel <= "001";
		output_reg_en <= '1';
		if decrypt_reg = '1' then
			enc_dec_sel <= '0';
			enc_dec_2_sel <= "001";
		end if;			
		if from_wait_pt = '1' then 
			next_state <= CORNER;
		else
			next_state <= OUTPUT_CT;
		end if;
	
	when CORNER =>
		bdo_valid_d <= '1';
		bdo_valid_en <= '1';
		bdo_valid_bytes_d <= "1";
		bdo_valid_bytes_en <= '1';
		end_of_block_d <= '1';
		end_of_block_en <= '1';
		bdo_reg_en <= '1';
		bdo_type_d <= "0101";
		bdo_type_en <= '1';
		if decrypt_reg = '1' then
		enc_dec_2_sel <= "010";
		output_reg_en <= '1';
			enc_dec_sel <= '1';
			inc_count_out <= '1';
		end if;
		next_state <= PERM_FINAL_LOAD;
		
	when OUTPUT_CT =>
		enc_dec_2_sel <= "010";
		output_reg_en <= '1';
		if eot_reg = '0' then
			if bdo_ready = '1' then
				inc_count_out <= '1';
				bdo_valid_d  <= '1';
				bdo_valid_en <= '1';
				bdo_valid_bytes_d <= "1";
				bdo_valid_bytes_en <= '1';
				end_of_block_d <= '1';
				end_of_block_en <= '1';
				bdo_reg_en <= '1';
				bdo_type_d <= "0101";
				bdo_type_en <= '1';
				if count_out = "111" then
					set_perm_start <= '1';
					set_rcin_to_6 <= '1'; --rcin <= x"6";
					if decrypt_reg = '1' then
						enc_dec_sel <= '1';
					end if;
					next_state <= PERM_PT;
				else
					next_state <= OUTPUT_CT;
				end if;
			end if;
		
		elsif eot_reg ='1' and pt_size = "1000" then 
			if bdo_ready = '1' then
				bdo_valid_d <= '1';
				bdo_valid_en <= '1';
				bdo_valid_bytes_d <= "1";
				bdo_valid_bytes_en <= '1';
				end_of_block_d <= '1';
				end_of_block_en <= '1';
				bdo_reg_en <= '1';
				bdo_type_d <= "0101";
				bdo_type_en <= '1';
				inc_count_out <= '1';
				if count_out = out_size then
					end_of_block_d <= '1';
					end_of_block_en <= '1';
					set_perm_start <= '1';
					set_rcin_to_6 <= '1'; --rcin <= x"6";
					next_state <= PERM_PT;
					if decrypt_reg = '1' then
						enc_dec_sel <= '1';
					end if;
				else
					end_of_block_d <= '0';
					end_of_block_en <= '1';
					next_state <= OUTPUT_CT;
				end if;
			end if;
			
		elsif eot_reg = '1' then
			if bdo_ready = '1' then
				bdo_valid_d <= '1';
				bdo_valid_en <= '1';
				bdo_valid_bytes_d <= "1";
				bdo_valid_bytes_en <= '1';
				end_of_block_d <= '1';
				end_of_block_en <= '1';
				bdo_reg_en <= '1';
				bdo_type_d <= "0101";
				bdo_type_en <= '1';
				inc_count_out <= '1';
				if count_out = out_size then
					end_of_block_d <= '1';
					end_of_block_en <= '1';
					if decrypt_reg = '1' then
						enc_dec_sel <= '1';
					end if;
					next_state <= PERM_FINAL_LOAD;
				else
					end_of_block_d <= '0';
					end_of_block_en <= '1';
					next_state <= OUTPUT_CT;
				end if;
			end if;
		end if;
		
	when PERM_PT =>
		if decrypt_reg = '1' and first_perm = '1' then
			rst_first_perm <= '1';
			enc_dec_sel <= '1';
		end if;
		if first_perm_pt = '1' then
			rst_first_perm_pt <= '1'; 
		end if;
		rst_perm_start <= '1';
		if perm_done = '1' then 
			if eoi_reg = '1' then
				if decrypt_reg = '1' then
					enc_dec_sel <= '1';
				end if;
				set_first_perm <= '1';
				next_state <= PERM_FINAL_LOAD;
			elsif eot_reg = '1' and pt_size = "1000" and decrypt_reg = '0' then 
				rst_ad_size <= '1'; --ad_size <= "000";
				if decrypt_reg = '1' then
					bdi_mux_1_sel <= "11";
				else
					bdi_mux_1_sel <= "01";
				end if;
				bdi_reg_1_en <= '1';
				rst_count_num <= '1';
				next_state <= PAD_PT_FINAL;	
			elsif eot_reg = '1' then
				if decrypt_reg = '1' then
					enc_dec_sel <= '1';
				end if;
				set_first_perm <= '1';
				next_state <= PERM_FINAL_LOAD;
			else 
				rst_pt_size_1 <= '1';
				set_first_perm <= '1';
				next_state <= WAIT_PT; 
			end if;
		else
			next_state <= PERM_PT;
		end if;
	
	when PERM_FINAL_LOAD =>
		key_mux_sel <= '0';
		key_reg_en <= '1';
		if pt_size_1 = '1'  and no_ct = '0' then
			nonce_mux_sel <= "011"; 
		else
			nonce_mux_sel <= "010";
		end if;
		nonce_reg_en <= '1';
		set_perm_start <= '1';
		set_rcin_to_c <= '1'; --rcin <= x"C";
		
		if no_pt = '1' then
			nonce_mux_sel <= "011";
			end_of_block_d <= '1';
			end_of_block_en <= '1';
		end if;
		
		if no_data = '1' then
			nonce_mux_sel <= "100";
			end_of_block_d <= '1';
			end_of_block_en <= '1';
		end if;	
		
		if no_ad = '1' and first_perm_pt = '0' then
			nonce_mux_sel <= "010";
			end_of_block_d <= '1';
			end_of_block_en <= '1';
		end if;

		next_state <= PERM_FINAL; 
		if decrypt_reg = '1' then
			if count_out = "000" then
				bdi_mux_2_sel <= "11";
				nonce_mux_sel <= "010";
				if no_data = '1' then
					nonce_mux_sel <= "100";
					nonce_reg_en <= '1';
					end_of_block_d <= '1';
					end_of_block_en <= '1';
				end if;
				if no_pt = '1' then
			         nonce_mux_sel <= "011";
			         end_of_block_d <= '1';
			         end_of_block_en <= '1';
		        end if;
				if no_ad = '1' and first_perm_pt = '0' then
					nonce_mux_sel <= "010";
					end_of_block_d <= '1';
					end_of_block_en <= '1';
				end if;
				nonce_reg_en <= '1';
				data_reg_en <= '1';
				enc_dec_sel <= '0';
			else
				enc_dec_sel <= '1';
				if output_reg_xor_1 = '1' then
					rst_output_reg_xor_1 <= '1';
					output_reg_en <= '1';
					enc_dec_2_sel <= "110";  
					set_perm_start <= '0';
					if no_pt = '1' then
			             nonce_mux_sel <= "011";
			             end_of_block_d <= '1';
			             end_of_block_en <= '1';
		            end if;
					next_state <= PERM_FINAL_LOAD;
				else
					if rot_count =  count_out then
						data_reg_en <= '1';
						bdi_mux_2_sel <= "10";
						if no_data = '1' then
							nonce_mux_sel <= "100";
							nonce_reg_en <= '1';
							end_of_block_d <= '1';
							end_of_block_en <= '1';
						end if;
						if no_pt = '1' then
			                 nonce_mux_sel <= "011";
			                 end_of_block_d <= '1';
			                 end_of_block_en <= '1';
		                end if;
						if no_ad = '1' and first_perm_pt = '0' then
							nonce_mux_sel <= "010";
							end_of_block_d <= '1';
							end_of_block_en <= '1';
						end if;
						next_state <= PERM_FINAL;
					else
						set_perm_start <= '0';
						inc_rot_count <= '1';
						output_reg_en <= '1';
						enc_dec_2_sel <= "101";
						next_state <= PERM_FINAL_LOAD;
					end if;
				end if;
			end if;
		end if;
	
	when PERM_FINAL =>
		if decrypt_reg = '1' and first_perm = '1' then
			rst_first_perm <= '1';
			enc_dec_sel <= '1';
		end if;
		rst_perm_start <= '1';
		if perm_done = '1' then 
			set_first_perm <= '1';
			next_state <= LOAD_TAG;
		else
		if decrypt_reg = '1' then
			enc_dec_sel <= '1'; 
		end if;
		if decrypt_reg = '1' and count_out = "000" then
			enc_dec_sel <= '0'; 
		end if;
		next_state <= PERM_FINAL;
		end if;
	
	when LOAD_TAG =>
		tag_reg_1_en <= '1';
		tag_reg_2_en <= '1';
		rst_count_out <= '1';
		rst_count_tag <= '1';
		if decrypt_reg = '1' then
			next_state <= LOAD_TAG_STORE;
		else
			next_state <= LOAD_TAG_1;
		end if;
		
	when LOAD_TAG_STORE =>
		if bdi_type = "1000" and bdi_valid = '1' then
			bdi_ready <= '1';
			tag_store_reg_en <= '1';
			next_state <= LOAD_TAG_STORE;
		else
			next_state <= COMPARE_TAG;
		end if;
		
	when COMPARE_TAG =>
		if msg_auth_ready = '1' then
			if tag_store_reg_out = tag_reg_1_out & tag_reg_2_out then
				msg_auth_valid <= '1';
				msg_auth <= '1';
			else
				msg_auth_valid <= '1';
				msg_auth <= '0';
			end if;
			next_state <= S_RESET;
		else
			next_state <= COMPARE_TAG;
		end if;
			
	
	when LOAD_TAG_1 =>
		enc_dec_2_sel <= "011";
		output_reg_en <= '1';
		next_state <= OUTPUT_TAG_1;
	
	when OUTPUT_TAG_1 =>
		if bdo_ready = '1' then
			enc_dec_2_sel <= "010";
			output_reg_en <= '1';
			bdo_valid_d <= '1';
			bdo_valid_en <= '1';
			bdo_valid_bytes_d <= "1";
			bdo_valid_bytes_en <= '1';
			bdo_reg_en <= '1';
			bdo_type_d <= "1000";
			bdo_type_en <= '1';
			inc_count_tag <= '1';
			if count_tag_out = "0111" then
				end_of_block_d <= '0';
				end_of_block_en <= '1';
				next_state <= LOAD_TAG_2;
			else
				end_of_block_d <= '0';
				end_of_block_en <= '1';
				next_state <= OUTPUT_TAG_1;
			end if;
		else
			next_state <= OUTPUT_TAG_1;
		end if;

	when LOAD_TAG_2 =>
		rst_count_tag <= '1';
		enc_dec_2_sel <= "100";
		output_reg_en <= '1';
		next_state <= OUTPUT_TAG_2;
		
	when OUTPUT_TAG_2 =>		
		if bdo_ready = '1' then
			enc_dec_2_sel <= "010";
			output_reg_en <= '1';
			bdo_valid_d <= '1';
			bdo_valid_en <= '1';
			bdo_valid_bytes_d <= "1";
			bdo_valid_bytes_en <= '1';
			bdo_reg_en <= '1';
			bdo_type_d <= "1000";
			bdo_type_en <= '1';
			inc_count_tag <= '1';
			if count_tag_out = "0111" then
				end_of_block_d <= '1';
				end_of_block_en <= '1';
				next_state <= S_RESET; 
			else
				end_of_block_d <= '0';
				end_of_block_en <= '1';
				next_state <= OUTPUT_TAG_2;
			end if;
		else
			next_state <= OUTPUT_TAG_2;
		end if;
	
	when others =>
	
	end case;
	
	end process;
	
end structure;

