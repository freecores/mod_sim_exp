----------------------------------------------------------------------  
----  mont_multiplier                                             ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    n-bit montgomery multiplier with a pipelined systolic     ----
----    array                                                     ----
----                                                              ----
----  Dependencies:                                               ----
----    - x_shift_reg                                             ----
----    - adder_n                                                 ----
----    - d_flip_flop                                             ----
----    - sys_pipeline                                            ----
----    - cell_1b_adder                                           ----
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
use ieee.std_logic_unsigned.all;

library mod_sim_exp;
use mod_sim_exp.mod_sim_exp_pkg.all;

-- Structural description of the montgommery multiply pipeline
-- contains the x operand shift register, my adder, the pipeline and 
-- reduction adder. To do a multiplication, the following actions must take place:
-- 
--    * load in the x operand in the shift register using the xy bus and load_x
--    * place the y operand on the xy bus for the rest of the operation
--    * generate a start pulse of 1 clk cycle long on start
--    * wait for ready signal
--    * result is avaiable on the r bus
-- 
entity mont_multiplier is
  generic (
    n          : integer := 1536; -- width of the operands
    nr_stages  : integer := 96; -- total number of stages
    stages_low : integer := 32  -- lower number of stages
  );
  port (
    -- clock input
    core_clk : in std_logic;
    -- operand inputs
    xy       : in std_logic_vector((n-1) downto 0); -- bus for x or y operand
    m        : in std_logic_vector((n-1) downto 0); -- modulus
    -- result output
    r        : out std_logic_vector((n-1) downto 0);  -- result
    -- control signals
    start    : in std_logic;
    reset    : in std_logic;
    p_sel    : in std_logic_vector(1 downto 0);
    load_x   : in std_logic;
    ready    : out std_logic
  );
end mont_multiplier;

architecture Structural of mont_multiplier is
  constant s  : integer := n/nr_stages;   -- stage width (# bits)
  
  signal reset_multiplier : std_logic;
  signal start_multiplier : std_logic;
  
  signal next_xi : std_logic;
  signal xi : std_logic;
  
  signal start_first_stage : std_logic;
  
begin

  -- multiplier is reset every calculation or reset
  reset_multiplier <= reset or start;

  -- start is delayed 1 cycle
  delay_1_cycle : d_flip_flop
  port map(
    core_clk => core_clk,
    reset    => reset,
    din      => start,
    dout     => start_multiplier
  );
  
  -- register to store the x value in 
  -- outputs the operand in serial using a shift register 
  x_selection : x_shift_reg
  generic map(
    n  => n,
    t  => nr_stages,
    tl => stages_low
  )
  port map(
    clk    => core_clk,
    reset  => reset,
    x_in   => xy,
    load_x => load_x,
    next_x => next_xi,
    p_sel  => p_sel,
    xi     => xi
  );
  
  -- stepping control logic to keep track off the multiplication and when it is done
  stepping_control : stepping_logic
  generic map(
    n => n, -- max nr of steps required to complete a multiplication
    t => nr_stages -- total nr of steps in the pipeline
  )
  port map(
    core_clk          => core_clk,
    start             => start_multiplier,
    reset             => reset_multiplier,
    t_sel             => nr_stages,
    n_sel             => n-1,
    start_first_stage => start_first_stage,
    stepping_done     => ready
  );
  
  systolic_array : sys_pipeline
  generic map(
    n  => n,
    t  => nr_stages,
    tl => stages_low
  )
  port map(
    core_clk => core_clk,
    y       => xy,
    m       => m,
    xi      => xi,
    next_x  => next_xi,
    start   => start_first_stage,
    reset   => reset_multiplier,
    p_sel   => p_sel,
    r       => r
  );
  
end Structural;

