----------------------------------------------------------------------  
----  sys_last_cell_logic                                         ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    last cell logic for use int the montogommery mulitplier   ----
----    pipelined systolic array                                  ----
----                                                              ----
----  Dependencies:                                               ----
----    - register_n                                              ----
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

-- logic needed as the last piece in the systolic array pipeline
-- calculates the last 2 bits of the cell_result and finishes the reduction
-- also generates the result selection signal
entity sys_last_cell_logic is
  port  (
    core_clk : in std_logic;    -- clock input
    reset    : in std_logic;    
    a_0      : out std_logic;   -- a_msb for last stage
    cin      : in std_logic;    -- cout from last stage
    red_cin  : in std_logic;    -- red_cout from last stage
    r_sel    : out std_logic;   -- result selection bit
    start    : in std_logic     -- done signal from last stage
  );
end sys_last_cell_logic;


architecture Behavorial of sys_last_cell_logic is
  signal cell_result_high       : std_logic_vector(1 downto 0);
  signal cell_result_high_reg   : std_logic_vector(1 downto 0);
  signal red_cout_end           : std_logic;
begin

  -- half adder: cout_last_stage + cell_result_high_reg(1)
  cell_result_high(0) <= cin xor cell_result_high_reg(1); --result
  cell_result_high(1) <= cin and cell_result_high_reg(1); --cout
  
  a_0 <= cell_result_high_reg(0);
  
  last_reg : register_n
  generic map(
    width => 2
  )
  port map(
    core_clk => core_clk,
    ce       => start,
    reset    => reset,
    din      => cell_result_high,
    dout     => cell_result_high_reg
  );
  
  -- reduction, finishing last 2 bits
  reduction_adder_a : cell_1b_adder
  port map(
    a     => '1', -- for 2s complement of m
    b     => cell_result_high_reg(0),
    cin   => red_cin,
    cout  => red_cout_end
  );

  reduction_adder_b : cell_1b_adder
  port map(
    a     => '1', -- for 2s complement of m
    b     => cell_result_high_reg(1),
    cin   => red_cout_end,
    cout  => r_sel
  );
  
end Behavorial;
