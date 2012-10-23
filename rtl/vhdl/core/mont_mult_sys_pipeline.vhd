----------------------------------------------------------------------  
----  mont_mult_sys_pipline                                       ---- 
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
----    - systolic_pipeline                                       ----
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library mod_sim_exp;
use mod_sim_exp.mod_sim_exp_pkg.all;


entity mont_mult_sys_pipeline is
  generic (
    n          : integer := 1536;
    nr_stages  : integer := 96; --(divides n, bits_low & (n-bits_low))
    stages_low : integer := 32
  );
  port (
    core_clk : in std_logic;
    xy       : in std_logic_vector((n-1) downto 0);
    m        : in std_logic_vector((n-1) downto 0);
    r        : out std_logic_vector((n-1) downto 0);
    start    : in std_logic;
    reset    : in std_logic;
    p_sel    : in std_logic_vector(1 downto 0);
    load_x   : in std_logic;
    ready    : out std_logic
  );
end mont_mult_sys_pipeline;


architecture Structural of mont_mult_sys_pipeline is
  constant stage_width : integer := n/nr_stages;
  constant bits_l      : integer := stage_width * stages_low;
  constant bits_h      : integer := n - bits_l;

  signal my               : std_logic_vector(n downto 0);
  signal my_h_cin         : std_logic;
  signal my_l_cout        : std_logic;
  signal r_pipeline       : std_logic_vector(n+1 downto 0);
  signal r_red            : std_logic_vector(n-1 downto 0);
  signal r_i              : std_logic_vector(n-1 downto 0);
  signal c_red_l          : std_logic_vector(2 downto 0);
  signal c_red_h          : std_logic_vector(2 downto 0);
  signal cin_red_h        : std_logic;
  signal r_sel            : std_logic;
  signal reset_multiplier : std_logic;
  signal start_multiplier : std_logic;
  signal m_inv            : std_logic_vector(n-1 downto 0);

  signal next_x_i : std_logic;
  signal x_i : std_logic;
begin

  -- x selection
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
    next_x => next_x_i,
    p_sel  => p_sel,
    x_i    => x_i
  );

  -- precomputation of my (m+y)
  my_adder_l : adder_n
  generic map(
    width       => bits_l,
    block_width => stage_width
  )
  port map(
    core_clk => core_clk,
    a        => m((bits_l-1) downto 0),
    b        => xy((bits_l-1) downto 0),
    cin      => '0',
    cout     => my_l_cout,
    r        => my((bits_l-1) downto 0)
  );
	
  my_adder_h : adder_n
  generic map(
    width       => bits_h,
    block_width => stage_width
  )
  port map(
    core_clk => core_clk,
    a        => m((n-1) downto bits_l),
    b        => xy((n-1) downto bits_l),
    cin      => my_h_cin,
    cout     => my(n),
    r        => my((n-1) downto bits_l)
  );

	my_h_cin <= '0' when (p_sel(1) and (not p_sel(0)))='1' else my_l_cout;
	
	-- multiplication	
	reset_multiplier <= reset or start;

  delay_1_cycle : d_flip_flop
  port map(
    core_clk => core_clk,
    reset    => reset,
    din      => start,
    dout     => start_multiplier
  );

  the_multiplier : systolic_pipeline
  generic map(
    n  => n, -- width of the operands (# bits)
    t  => nr_stages,  -- number of stages (divider of n) >= 2
    tl => stages_low
  )
  port map(
    core_clk => core_clk,
    my       => my,
    y        => xy,
    m        => m,
    xi       => x_i,
    start    => start_multiplier,
    reset    => reset_multiplier,
    p_sel    => p_sel,
    ready    => ready, -- misschien net iets te vroeg?
    next_x   => next_x_i,
    r        => r_pipeline
  );
	
	-- post-computation (reduction)
	m_inv <= not(m);
	
  reduction_adder_l : adder_n
  generic map(
    width       => bits_l,
    block_width => stage_width
  )
  port map(
    core_clk => core_clk,
    a        => m_inv((bits_l-1) downto 0),
    b        => r_pipeline((bits_l-1) downto 0),
    cin      => '1',
    cout     => c_red_l(0),
    r        => r_red((bits_l-1) downto 0)
  );

  reduction_adder_l_a : cell_1b_adder
  port map(
    a    => '1',
    b    => r_pipeline(bits_l),
    cin  => c_red_l(0),
    cout => c_red_l(1)
    --r => 
  );

  reduction_adder_l_b : cell_1b_adder
  port map(
    a     => '1',
    b     => r_pipeline(bits_l+1),
    cin   => c_red_l(1),
    cout  => c_red_l(2)
    -- r => 
  );
	
	--cin_red_h <= p_sel(1) and (not p_sel(0));
	cin_red_h <= c_red_l(0) when p_sel(0) = '1' else '1';
	
  reduction_adder_h : adder_n
  generic map(
    width       => bits_h,
    block_width => stage_width
  )
  port map(
    core_clk => core_clk,
    a        => m_inv((n-1) downto bits_l),
    b        => r_pipeline((n-1) downto bits_l),
    cin      => cin_red_h,
    cout     => c_red_h(0),
    r        => r_red((n-1) downto bits_l)
  );

  reduction_adder_h_a : cell_1b_adder
  port map(
    a     => '1',
    b     => r_pipeline(n),
    cin   => c_red_h(0),
    cout  => c_red_h(1)
  );

  reduction_adder_h_b : cell_1b_adder
  port map(
    a     => '1',
    b     => r_pipeline(n+1),
    cin   => c_red_h(1),
    cout  => c_red_h(2)
  );
  
	r_sel <= (c_red_h(2) and p_sel(1)) or (c_red_l(2) and (p_sel(0) and (not p_sel(1))));
	r_i <= r_red when r_sel = '1' else r_pipeline((n-1) downto 0);
	
	-- output
	r <= r_i;
end Structural;