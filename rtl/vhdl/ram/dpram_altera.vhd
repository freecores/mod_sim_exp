-- Quartus II VHDL Template
--
-- Simple Dual-Port RAM with separate read and write addresses and data widths
-- that are controlled by the parameters RW and WW.  RW and WW must specify a
-- read/write ratio that's supported by the memory blocks in your target
-- device.  Otherwise, no RAM will be inferred.  

library ieee;
use ieee.std_logic_1164.all;
library altera;
use altera.altera_standard_functions.all;

entity dpram_altera is
    
	generic (
		WORDS : natural := 2;
		RW    : natural := 1024;
		WW    : natural := 32);

	port (
		we    : in std_logic;
		clk   : in std_logic;
		waddr : in natural range 0 to (WORDS * maximum(RW, WW)) / WW - 1;
		wdata : in std_logic_vector(WW - 1 downto 0);
		raddr : in natural range 0 to (WORDS * maximum(RW, WW)) / RW - 1;
		q     : out std_logic_vector(RW - 1 downto 0));

end dpram_altera;

architecture rtl of dpram_altera is

	constant B : natural := minimum(RW, WW);
	constant R : natural := maximum(RW, WW)/B;

	-- Use a multidimensional array to model mixed-width 
	type word_t is array(R - 1 downto 0) of std_logic_vector(B - 1 downto 0);
	type ram_t is array (0 to WORDS - 1) of word_t;

	signal ram : ram_t;
    
begin  -- rtl

	-- Must handle read < write and write > read separately 
	smaller_read: if RW < WW generate
		signal wdata_local : word_t;
	begin 

		-- Re-organize the write data to match the RAM word type
		unpack: for i in 0 to R - 1 generate    
			wdata_local(i) <= wdata(B*(i+1) - 1 downto B*i);
		end generate unpack;

		process(clk, we)
		begin
			if(rising_edge(clk)) then 
				if(we = '1') then
					ram(waddr) <= wdata_local;
				end if;
				q <= ram(raddr / R )(raddr mod R);
			end if;
		end process;  
	end generate smaller_read;

	not_smaller_read: if RW >= WW generate
		signal q_local : word_t;
	begin

		-- Re-organize the read data from the RAM to match the output
		unpack: for i in 0 to R - 1 generate    
			q(B*(i+1) - 1 downto B*i) <= q_local(i);
		end generate unpack;
        
		process(clk, we)
		begin
			if(rising_edge(clk)) then 
				if(we = '1') then
					ram(waddr / R)(waddr mod R) <= wdata;
				end if;
				q_local <= ram(raddr);
			end if;
		end process;  
	end generate not_smaller_read;

end rtl;
