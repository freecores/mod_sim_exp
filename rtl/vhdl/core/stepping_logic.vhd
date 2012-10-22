----------------------------------------------------------------------  
----  stepping_logic                                              ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    stepping logic for the pipelined montgomery multiplier    ----
----                                                              ----
----  Dependencies:                                               ----
----    - d_flip_flop                                             ----
----    - counter_sync                                            ----
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


entity stepping_logic is
  generic(
    n : integer := 1536; -- max nr of steps required to complete a multiplication
    t : integer := 192 -- total nr of steps in the pipeline
  );
  port(
    core_clk          : in  std_logic;
    start             : in  std_logic;
    reset             : in  std_logic;
    t_sel             : in integer range 0 to t; -- nr of stages in the pipeline piece
    n_sel             : in integer range 0 to n; -- nr of steps required for a complete multiplication
    start_first_stage : out std_logic;
    stepping_done     : out std_logic
  );
end stepping_logic;


architecture Behavioral of stepping_logic is
  signal laststeps_in_i      : std_logic := '0';
  signal laststeps_out_i     : std_logic := '0';
  signal start_stop_in_i     : std_logic := '0';
  signal start_stop_out_i    : std_logic := '0';
  signal steps_in_i          : std_logic := '0';
  signal steps_out_i         : std_logic := '0';
  signal substeps_in_i       : std_logic := '0';
  signal substeps_out_i      : std_logic := '0';
  signal done_reg_in_i       : std_logic := '0';
  signal done_reg_out_i      : std_logic := '0';
  signal start_first_stage_i : std_logic := '0';
  signal start_i : std_logic := '0';

begin
	start_i <= start;

	-- map outputs
	start_first_stage <= start_first_stage_i;
	stepping_done <= laststeps_out_i;
	
	-- internal signals
	start_stop_in_i <= start_i or (start_stop_out_i and not steps_out_i);
	substeps_in_i <= start_stop_in_i;
	steps_in_i <= substeps_out_i;
	done_reg_in_i <= steps_out_i or (done_reg_out_i and not laststeps_out_i);
	laststeps_in_i <= done_reg_in_i;
	start_first_stage_i <= start_i or steps_in_i;
	--start_first_stage_i <= steps_in_i;
	
  done_reg : d_flip_flop
  port map(
    core_clk => core_clk,
    reset    => reset,
    din      => done_reg_in_i,
    dout     => done_reg_out_i
  );

  start_stop_reg : d_flip_flop
  port map(
    core_clk => core_clk,
    reset    => reset,
    din      => start_stop_in_i,
    dout     => start_stop_out_i
  );

  -- for counting the last steps
  laststeps_counter : counter_sync
  generic map(
    max_value => t
  )
  port map(
    reset_value => t_sel,
    core_clk    => core_clk,
    ce          => laststeps_in_i,
    reset       => reset,
    overflow    => laststeps_out_i
  );

  -- counter for keeping track of the steps
  steps_counter : counter_sync
  generic map(
    max_value => n
  )
  port map(
    reset_value => (n_sel),
    core_clk    => core_clk,
    ce          => steps_in_i,
    reset       => reset,
    overflow    => steps_out_i
  );

  -- makes sure we don't start too early with a new step
  substeps_counter : counter_sync
  generic map(
    max_value => 2
  )
  port map(
    reset_value => 2,
    core_clk    => core_clk,
    ce          => substeps_in_i,
    reset       => reset,
    overflow    => substeps_out_i
  );

end Behavioral;