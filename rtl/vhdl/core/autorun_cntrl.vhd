----------------------------------------------------------------------  
----  autorun_ctrl                                                ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----     autorun control unit for a pipelined montgomery          ----
----     multiplier                                               ----
----                                                              ----
----  Dependencies: none                                          ----
----                                                              ----
----  Authors:                                                    ----
----      - Geoffrey Ottoy, DraMCo research group                 ----
----      - Jonas De Craene, JonasDC@opencores.org                ---- 
----                                                              ---- 
---------------------------------------------------------------------- 
----                                                              ---- 
---- Copyright (C) 2011 DraMCo research group and OPENCORES.ORG   ---- 
----                                                              ---- 
---- This source file may be used and distributed without         ---- 
---- restriction provided that this copyright statement is not    ---- 
---- removed from the file and that any derivative work contains  ---- 
---- the original copyright notice and the associated disclaimer. ---- 
----                                                              ---- 
---- This source file is free software; you can redistribute it   ---- 
---- and/or modify it under the terms of the GNU Lesser General   ---- 
---- Public License as published by the Free Software Foundation; ---- 
---- either version 2.1 of the License, or (at your option) any   ---- 
---- later version.                                               ---- 
----                                                              ---- 
---- This source is distributed in the hope that it will be       ---- 
---- useful, but WITHOUT ANY WARRANTY; without even the implied   ---- 
---- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ---- 
---- PURPOSE.  See the GNU Lesser General Public License for more ---- 
---- details.                                                     ---- 
----                                                              ---- 
---- You should have received a copy of the GNU Lesser General    ---- 
---- Public License along with this source; if not, download it   ---- 
---- from http://www.opencores.org/lgpl.shtml                     ---- 
----                                                              ---- 
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity autorun_cntrl is
  port (
    clk              : in  std_logic;
    reset            : in  std_logic;
    start            : in  std_logic;
    done             : out  std_logic;
    op_sel           : out  std_logic_vector (1 downto 0);
    start_multiplier : out  std_logic;
    multiplier_done  : in  std_logic;
    read_buffer      : out  std_logic;
    buffer_din       : in  std_logic_vector (31 downto 0);
    buffer_empty     : in  std_logic
  );
end autorun_cntrl;


architecture Behavioral of autorun_cntrl is

  signal bit_counter_i    : integer range 0 to 15 := 0;
  signal bit_counter_0_i  : std_logic;
  signal bit_counter_15_i : std_logic;
  signal next_bit_i       : std_logic := '0';
  signal next_bit_del_i   : std_logic;
  
  signal start_cycle_i     : std_logic := '0';
  signal start_cycle_del_i : std_logic;
  
  signal done_i    : std_logic;
  signal start_i   : std_logic;
  signal running_i : std_logic;
  
  signal start_multiplier_i     : std_logic;
  signal start_multiplier_del_i : std_logic;
  signal mult_done_del_i        : std_logic;
  
  signal e0_i            : std_logic_vector(15 downto 0);
  signal e1_i            : std_logic_vector(15 downto 0);
  signal e0_bit_i        : std_logic;
  signal e1_bit_i        : std_logic;
  signal e_bits_i        : std_logic_vector(1 downto 0);
  signal e_bits_0_i      : std_logic;
  signal cycle_counter_i : std_logic;
  signal op_sel_sel_i    : std_logic;
  signal op_sel_i        : std_logic_vector(1 downto 0);
begin

	done <= done_i;
	
	-- the two exponents
	e0_i <= buffer_din(15 downto 0);
	e1_i <= buffer_din(31 downto 16);

	-- generate the index to select a single bit from the two exponents
	SYNC_BIT_COUNTER: process (clk, reset)
	begin
		if reset = '1' then
			bit_counter_i <= 15;
		elsif rising_edge(clk) then
			if start = '1' then -- make sure we start @ bit 0
				bit_counter_i <= 15;
			elsif next_bit_i = '1' then -- count
				if bit_counter_i = 0 then
					bit_counter_i <= 15;
				else
					bit_counter_i <= bit_counter_i - 1;
				end if;
			end if;
		end if;
	end process SYNC_BIT_COUNTER;
	-- signal when bit_counter_i = 0
	bit_counter_0_i <= '1' when bit_counter_i=0 else '0';
	bit_counter_15_i <= '1' when bit_counter_i=15 else '0';
	-- the bits...
	e0_bit_i <= e0_i(bit_counter_i);
	e1_bit_i <= e1_i(bit_counter_i);
	e_bits_i <= e0_bit_i & e1_bit_i;
	e_bits_0_i <= '1' when (e_bits_i = "00") else '0';
	
	-- operand pre-select
	with e_bits_i select
		op_sel_i <= "00" when "10", -- gt0
						"01" when "01", -- gt1
						"10" when "11", -- gt01
						"11" when others;
						
	-- select operands
	op_sel_sel_i <= '0' when e_bits_0_i = '1' else (cycle_counter_i);
	op_sel <= op_sel_i when op_sel_sel_i = '1' else "11";
	
	-- process that drives running_i signal ('1' when in autorun, '0' when not)
	RUNNING_PROC: process(clk, reset)
	begin
		if reset = '1' then
			running_i <= '0';
		elsif rising_edge(clk) then
			running_i <= start or (running_i and (not done_i));
		end if;
	end process RUNNING_PROC;
	
	-- ctrl logic
	start_multiplier_i <= start_cycle_del_i or (mult_done_del_i and (cycle_counter_i) and (not e_bits_0_i));
	read_buffer <= start_cycle_del_i and bit_counter_15_i and running_i; -- pop new word from fifo when bit_counter is back at '15'
	start_multiplier <= start_multiplier_del_i and running_i;
	
	-- start/stop logic
	start_cycle_i <= (start and (not buffer_empty)) or next_bit_i; -- start pulse (external or internal)
	done_i <= (start and buffer_empty) or (next_bit_i and bit_counter_0_i and buffer_empty); -- stop when buffer is empty
	next_bit_i <= (mult_done_del_i and e_bits_0_i) or (mult_done_del_i and (not e_bits_0_i) and (not cycle_counter_i));

	-- process for delaying signals with 1 clock cycle
	DEL_PROC: process(clk)
	begin
		if rising_edge(clk) then
			start_multiplier_del_i <= start_multiplier_i;
			start_cycle_del_i <= start_cycle_i;
			mult_done_del_i <= multiplier_done;
		end if;
	end process DEL_PROC;
	
	-- process for delaying signals with 1 clock cycle
	CYCLE_CNTR_PROC: process(clk, start)
	begin
		if start = '1' or reset = '1' then
			cycle_counter_i <= '0';
		elsif rising_edge(clk) then
			if (e_bits_0_i = '0') and (multiplier_done = '1') then
				cycle_counter_i <= not cycle_counter_i;
			elsif (e_bits_0_i = '1') and (multiplier_done = '1') then
				cycle_counter_i <= '0';
			else
				cycle_counter_i <= cycle_counter_i;
			end if;
		end if;
	end process CYCLE_CNTR_PROC;
	
end Behavioral;

