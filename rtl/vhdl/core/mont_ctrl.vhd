----------------------------------------------------------------------  
----  mont_ctrl                                                   ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    control unit for a pipelined montgomery multiplier, with  ----
----    split pipeline operation and "auto-run" support           ----
----                                                              ----
----  Dependencies:                                               ----
----    - autorun_cntrl                                           ----
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

library mod_sim_exp;
use mod_sim_exp.mod_sim_exp_pkg.all;


entity mont_ctrl is
  port (
    clk   : in std_logic;
    reset : in std_logic;
      -- bus side
    start           : in std_logic;
    x_sel_single    : in std_logic_vector(1 downto 0);
    y_sel_single    : in std_logic_vector(1 downto 0);
    run_auto        : in std_logic;
    op_buffer_empty : in std_logic;
    op_sel_buffer   : in std_logic_vector(31 downto 0);
    read_buffer     : out std_logic;
    buffer_noread   : in std_logic;
    done            : out std_logic;
    calc_time       : out std_logic;
      -- multiplier side
    op_sel           : out std_logic_vector(1 downto 0);
    load_x           : out std_logic;
    load_result      : out std_logic;
    start_multiplier : out std_logic;
    multiplier_ready : in std_logic
  );
end mont_ctrl;


architecture Behavioral of mont_ctrl is
  signal start_delayed_i      : std_logic; -- delayed version of start input
  signal start_pulse_i        : std_logic;
  signal auto_start_pulse_i   : std_logic;
  signal start_multiplier_i   : std_logic;
  signal start_up_counter_i   : std_logic_vector(2 downto 0) := "100"; -- used in op_sel at multiplier start
  signal auto_start_i         : std_logic := '0';
  signal store_autorun_i      : std_logic;
  signal run_auto_i           : std_logic;
  signal run_auto_stored_i    : std_logic := '0';
  signal single_start_pulse_i : std_logic;

  signal calc_time_i : std_logic; -- high ('1') during multiplication

  signal x_sel_i        : std_logic_vector(1 downto 0); -- the operand used as x input
  signal y_sel_i        : std_logic_vector(1 downto 0); -- the operand used as y input
  signal x_sel_buffer_i : std_logic_vector(1 downto 0); -- x operand as specified by fifo buffer (autorun)

  signal auto_done_i             : std_logic;
  signal start_auto_i            : std_logic;
  signal new_buf_part_i          : std_logic;
  signal new_buf_word_i          : std_logic;
  signal buf_part_i              : std_logic_vector(3 downto 0);
  signal pop_i                   : std_logic;
  signal start_autorun_cycle_i   : std_logic;
  signal start_autorun_cycle_1_i : std_logic;
  signal autorun_counter_i       : std_logic_vector(1 downto 0);
  signal part_counter_i          : std_logic_vector(2 downto 0);
  signal auto_multiplier_done_i : std_logic;
	
begin

	-----------------------------------------------------------------------------------
	-- Processes related to starting and stopping the multiplier
	-----------------------------------------------------------------------------------
	-- generate a start pulse (duration 1 clock cycle) based on ext. start sig
	START_PULSE_PROC: process(clk)
	begin
		if rising_edge(clk) then
			start_delayed_i <= start;
		end if;
	end process START_PULSE_PROC;
	start_pulse_i <= start and (not start_delayed_i);
	single_start_pulse_i <= start_pulse_i and (not run_auto_i);
	start_auto_i <= start_pulse_i and run_auto_i;

	-- to start the multiplier we first need to select the y_operand and
	-- clock it in the y_register
	-- the we select the x_operand and start the multiplier
	START_MULT_PROC: process(clk, reset)
	begin
		if reset = '1' then
			start_up_counter_i <= "100";
		elsif rising_edge(clk) then
			if start_pulse_i = '1' or auto_start_pulse_i = '1' then
				start_up_counter_i <= "000";
			elsif start_up_counter_i(2) /= '1' then
				start_up_counter_i <= start_up_counter_i + '1';
			else
				start_up_counter_i <= "100";
			end if;
		else
			start_up_counter_i <= start_up_counter_i;
		end if;
	end process;
	
	-- select operands (autorun/single run)
	x_sel_i <= x_sel_buffer_i when (run_auto_i = '1') else x_sel_single;
	y_sel_i <= "11" when (run_auto_i = '1') else y_sel_single; -- y is operand3 in auto mode
	
	-- clock operands to operand_mem output (first y, then x)
	with start_up_counter_i(2 downto 1) select
		op_sel <= y_sel_i when "00",
		          x_sel_i when others;
	load_x <= start_up_counter_i(0) and (not start_up_counter_i(1));
	-- start multiplier
	start_multiplier_i <= start_up_counter_i(1) and start_up_counter_i(0);
	start_multiplier <= start_multiplier_i;

	-- signal calc time is high during multiplication
	CALC_TIME_PROC: process(clk, reset)
	begin
		if reset = '1' then
			calc_time_i <= '0';
		elsif rising_edge(clk) then
			if start_multiplier_i = '1' then
				calc_time_i <= '1';
			elsif multiplier_ready = '1' then
				calc_time_i <= '0';
			else
				calc_time_i <= calc_time_i;
			end if;
		else
			calc_time_i <= calc_time_i;
		end if;
	end process CALC_TIME_PROC;
	calc_time <= calc_time_i;
	
	-- what happens when a multiplication has finished
	load_result <= multiplier_ready;
	-- ignore multiplier_ready when in automode, the logic will assert auto_done_i when finished
	done <= ((not run_auto_i) and multiplier_ready) or auto_done_i; 
	
	-----------------------------------------------------------------------------------
	-- Processes related to op_buffer cntrl and auto_run mode
	-- start_auto_i     -> start autorun mode operation
	-- auto_start_pulse <- autorun logic starts the multiplier
	-- auto_done        <- autorun logic signals when autorun operation has finished
	-- x_sel_buffer_i   <- autorun logic determines which operand is used as x
	
	-- check buffer empty signal
	-----------------------------------------------------------------------------------
	
	-- at the beginning of each new multiplication we store the current autorun bit
--	STORE_AUTORUN_PROC: process(clk)
--	begin
--		if rising_edge(clk) then
--			if store_autorun_i = '1' then
--				run_auto_stored_i <= run_auto;
--			else
--				run_auto_stored_i <= run_auto_stored_i;
--			end if;
--		end if;
--	end process STORE_AUTORUN_PROC;
	run_auto_i <= run_auto;
	
	-- multiplier_ready is only passed to autorun control when in autorun mode
	auto_multiplier_done_i <= (multiplier_ready and run_auto_i);
	
  autorun_control_logic : autorun_cntrl port map(
    clk              => clk,
    reset            => reset,
    start            => start_auto_i,
    done             => auto_done_i,
    op_sel           => x_sel_buffer_i,
    start_multiplier => auto_start_pulse_i,
    multiplier_done  => auto_multiplier_done_i,
    read_buffer      => read_buffer,
    buffer_din       => op_sel_buffer,
    buffer_empty     => op_buffer_empty
  );

end Behavioral;