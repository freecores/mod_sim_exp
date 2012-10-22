----------------------------------------------------------------------  
----  multiplier_core                                             ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    toplevel of a modular simultaneous exponentiation core    ----
----    using a pipelined montgommery multiplier with split       ----
----    pipeline support and auto-run support                     ----
----                                                              ----
----  Dependencies:                                               ----
----    - mont_mult_sys_pipeline                                  ----
----    - operand_mem                                             ----
----    - fifo_primitive                                          ----
----    - mont_ctrl                                               ----
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


entity multiplier_core is
  port(
    clk   : in  std_logic;
    reset : in  std_logic;
      -- operand memory interface (plb shared memory)
    write_enable : in  std_logic;
    data_in      : in  std_logic_vector (31 downto 0);
    rw_address   : in  std_logic_vector (8 downto 0);
    data_out     : out std_logic_vector (31 downto 0);
    collision    : out std_logic;
      -- op_sel fifo interface
    fifo_din    : in  std_logic_vector (31 downto 0);
    fifo_push   : in  std_logic;
    fifo_full   : out std_logic;
    fifo_nopush : out std_logic;
      -- ctrl signals
    start          : in  std_logic;
    run_auto       : in  std_logic;
    ready          : out std_logic;
    x_sel_single   : in  std_logic_vector (1 downto 0);
    y_sel_single   : in  std_logic_vector (1 downto 0);
    dest_op_single : in  std_logic_vector (1 downto 0);
    p_sel          : in  std_logic_vector (1 downto 0);
    calc_time      : out std_logic
  );
end multiplier_core;


architecture Behavioral of multiplier_core is
  signal xy_i : std_logic_vector(1535 downto 0);
  signal x_i  : std_logic;
  signal m    : std_logic_vector(1535 downto 0);
  signal r    : std_logic_vector(1535 downto 0);

  signal op_sel           : std_logic_vector(1 downto 0);
  signal result_dest_op_i : std_logic_vector(1 downto 0);
  signal mult_ready       : std_logic;
  signal start_mult       : std_logic;
  signal load_op          : std_logic;
  signal load_x_i         : std_logic;
  signal load_m           : std_logic;
  signal load_result      : std_logic;

  signal fifo_empty : std_logic;
  signal fifo_pop   : std_logic;
  signal fifo_nopop : std_logic;
  signal fifo_dout  : std_logic_vector(31 downto 0);
  --signal fifo_push : std_logic;

  constant n : integer := 1536;
  constant t : integer := 96;
  constant tl : integer := 32;

begin

  -- The actual multiplier
  the_multiplier : mont_mult_sys_pipeline generic map(
    n          => n,
    nr_stages  => t, --(divides n, bits_low & (n-bits_low))
    stages_low => tl
  )
  port map(
    core_clk => clk,
    xy       => xy_i,
    m        => m,
    r        => r,
    start    => start_mult,
    reset    => reset,
    p_sel    => p_sel,
    load_x   => load_x_i,
    ready    => mult_ready
  );

  -- Block ram memory for storing the operands and the modulus
  the_memory : operand_mem port map(
    data_in        => data_in,
    data_out       => data_out,
    rw_address     => rw_address,
    op_sel         => op_sel,
    xy_out         => xy_i,
    m              => m,
    result_in      => r,
    load_op        => load_op,
    load_m         => load_m,
    load_result    => load_result,
    result_dest_op => result_dest_op_i,
    collision      => collision,
    clk            => clk
  );

	load_op <= write_enable when (rw_address(8) = '0') else '0';
	load_m <= write_enable when (rw_address(8) = '1') else '0';
	result_dest_op_i <= dest_op_single when run_auto = '0' else "11"; -- in autorun mode we always store the result in operand3
	
  -- A fifo for auto-run operand selection
  the_exponent_fifo : fifo_primitive port map(
    clk    => clk,
    din    => fifo_din,
    dout   => fifo_dout,
    empty  => fifo_empty,
    full   => fifo_full,
    push   => fifo_push,
    pop    => fifo_pop,
    reset  => reset,
    nopop  => fifo_nopop,
    nopush => fifo_nopush
  );
	
  -- The control logic for the core
  the_control_unit : mont_ctrl port map(
    clk              => clk,
    reset            => reset,
    start            => start,
    x_sel_single     => x_sel_single,
    y_sel_single     => y_sel_single,
    run_auto         => run_auto,
    op_buffer_empty  => fifo_empty,
    op_sel_buffer    => fifo_dout,
    read_buffer      => fifo_pop,
    buffer_noread    => fifo_nopop,
    done             => ready,
    calc_time        => calc_time,
    op_sel           => op_sel,
    load_x           => load_x_i,
    load_result      => load_result,
    start_multiplier => start_mult,
    multiplier_ready => mult_ready
  );

end Behavioral;
