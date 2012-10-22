----------------------------------------------------------------------  
----  systolic_pipeline                                           ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    pipelined systolic array implementation of a montgomery   ----
----    multiplier                                                ----
----                                                              ----
----  Dependencies:                                               ----
----    - stepping_logic                                          ----
----    - first_stage                                             ----
----    - standard_stage                                          ----
----    - last_stage                                              ----
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


-- p_sel: 
-- 01 = lower part
-- 10 = upper part
-- 11 = full range

entity systolic_pipeline is
  generic(
    n  : integer := 1536; -- width of the operands (# bits)
    t  : integer := 192;  -- number of stages (divider of n) >= 2
    tl : integer := 64    -- best take t = sqrt(n)
  );
  port(
    core_clk : in  std_logic;
    my       : in  std_logic_vector((n) downto 0);
    y        : in  std_logic_vector((n-1) downto 0);
    m        : in  std_logic_vector((n-1) downto 0);
    xi       : in  std_logic;
    start    : in  std_logic;
    reset    : in  std_logic;
    p_sel    : in  std_logic_vector(1 downto 0); -- select which piece of the multiplier will be used
    ready    : out std_logic;
    next_x   : out std_logic;
    r        : out std_logic_vector((n+1) downto 0)
  );
end systolic_pipeline;


architecture Structural of systolic_pipeline is
  constant s      : integer := n/t; -- defines the size of the stages (# bits)
  constant size_l : integer := s*tl;
  constant size_h : integer :=  n - size_l;

  signal start_stage_i : std_logic_vector((t-1) downto 0);
  --signal stage_ready_i : std_logic_vector((t-1) downto 0);
  signal stage_done_i : std_logic_vector((t-2) downto 0);

  signal x_i   : std_logic_vector((t-1) downto 0) := (others => '0');
  signal q_i   : std_logic_vector((t-2) downto 0) := (others => '0');
  signal c_i   : std_logic_vector((t-2) downto 0) := (others => '0');
  signal a_i   : std_logic_vector((n+1) downto 0) := (others => '0');
  signal r_tot : std_logic_vector((n+1) downto 0) := (others => '0');
  signal r_h   : std_logic_vector(s-1 downto 0) := (others => '0');
  signal r_l   : std_logic_vector((s+1) downto 0) := (others => '0');
  signal a_h   : std_logic_vector((s*2)-1 downto 0) := (others => '0');
  signal a_l   : std_logic_vector((s*2)-1 downto 0) := (others => '0');

  --signal ready_i : std_logic;
  signal stepping_done_i : std_logic;
  signal t_sel           : integer range 0 to t := t;
  signal n_sel           : integer range 0 to n := n;
  signal split           : std_logic := '0';
  signal lower_e_i       : std_logic := '0';
  signal higher_e_i      : std_logic := '0';
  signal start_pulses_i  : std_logic := '0';
  signal start_higher_i  : std_logic := '0';
  signal higher_0_done_i : std_logic := '0';
  signal h_x_0, h_x_1    : std_logic := '0';
  signal h_q_0, h_q_1    : std_logic := '0';
  signal h_c_0, h_c_1    : std_logic := '0';
  signal x_offset_i      : integer range 0 to tl*s := 0;
  signal next_x_i : std_logic := '0';

begin

	-- output mapping
	r <= a_i; -- mogelijks moet er nog een shift operatie gebeuren
	ready <= stepping_done_i;

	-- result feedback
	a_i((n+1) downto ((tl+1)*s)) <= r_tot((n+1) downto ((tl+1)*s));
	a_i(((tl-1)*s-1) downto 0) <= r_tot(((tl-1)*s-1) downto 0);
	
	a_l((s+1) downto 0) <= r_l;
	a_h((s*2)-1 downto s) <= r_h; 
	with p_sel select
		a_i(((tl+1)*s-1) downto ((tl-1)*s)) <= a_l when "01",
		a_h  when "10",
		r_tot(((tl+1)*s-1) downto ((tl-1)*s)) when others;

	-- signals from x_selection
	next_x_i <= start_stage_i(1) or (start_stage_i(tl+1) and higher_e_i);
	--
	next_x <= next_x_i;
	x_i(0) <= xi;
	
	-- this module controls the pipeline operation
	with p_sel select
		t_sel <=    tl when "01",
		          t-tl when "10",
					       t when others;
					
	with p_sel select
		n_sel <= size_l-1 when "01",
					   size_h-1 when "10",
					        n-1 when others;
	
	with p_sel select
		lower_e_i <=  '0' when "10",
						      '1' when others;
	
	with p_sel select
		higher_e_i <= '1' when "10",
						      '0' when others;
	
	split <= p_sel(0) and p_sel(1);
	
	
  stepping_control : stepping_logic
  generic map(
    n => n, -- max nr of steps required to complete a multiplication
    t => t -- total nr of steps in the pipeline
  )
  port map(
    core_clk          => core_clk,
    start             => start,
    reset             => reset,
    t_sel             => t_sel,
    n_sel             => n_sel,
    start_first_stage => start_pulses_i,
    stepping_done     => stepping_done_i
  );
	
	-- start signals for first stage of lower and higher part
	start_stage_i(0) <= start_pulses_i and lower_e_i;
	start_higher_i <= start_pulses_i and (higher_e_i and not split);
	
	-- start signals for stage tl and tl+1 (full pipeline operation)
	start_stage_i(tl) <= stage_done_i(tl-1) and split;
	start_stage_i(tl+1) <= stage_done_i(tl) or higher_0_done_i;
	
	-- nothing special here, previous stages starts the next
	start_signals_l: for i in 1 to tl-1 generate
    start_stage_i(i) <= stage_done_i(i-1);
	end generate;
	
	start_signals_h: for i in tl+2 to t-1 generate
    start_stage_i(i) <= stage_done_i(i-1);
	end generate;

  stage_0 : first_stage
  generic map(
    width => s
  )
  port map(
    core_clk => core_clk,
    my       => my(s downto 0),
    y        => y(s downto 0),
    m        => m(s downto 0),
    xin      => x_i(0),
    xout     => x_i(1),
    qout     => q_i(0),
    a_msb    => a_i(s),
    cout     => c_i(0),
    start    => start_stage_i(0),
    reset    => reset,
        --ready => stage_ready_i(0),
    done => stage_done_i(0),
    r    => r_tot((s-1) downto 0)
  );
	
  stages_l : for i in 1 to (tl) generate
    standard_stages : standard_stage
    generic map(
      width => s
    )
    port map(
      core_clk => core_clk,
      my       => my(((i+1)*s) downto ((s*i)+1)),
      y        => y(((i+1)*s) downto ((s*i)+1)),
      m        => m(((i+1)*s) downto ((s*i)+1)),
      xin      => x_i(i),
      qin      => q_i(i-1),
      xout     => x_i(i+1),
      qout     => q_i(i),
      a_msb    => a_i((i+1)*s),
      cin      => c_i(i-1),
      cout     => c_i(i),
      start    => start_stage_i(i),
      reset    => reset,
          --ready => stage_ready_i(i),
      done => stage_done_i(i),
      r    => r_tot((((i+1)*s)-1) downto (s*i))
    );
  end generate;
	
	h_c_1 <= h_c_0 or c_i(tl);
	h_q_1 <= h_q_0 or q_i(tl);
	h_x_1 <= h_x_0 or x_i(tl+1);
	
  stage_tl_1 : standard_stage
  generic map(
    width => s
  )
  port map(
    core_clk => core_clk,
    my       => my(((tl+2)*s) downto ((s*(tl+1))+1)),
    y        => y(((tl+2)*s) downto ((s*(tl+1))+1)),
    m        => m(((tl+2)*s) downto ((s*(tl+1))+1)),
           --xin => x_i(tl+1),
    xin => h_x_1,
           --qin => q_i(tl),
    qin   => h_q_1,
    xout  => x_i(tl+2),
    qout  => q_i(tl+1),
    a_msb => a_i((tl+2)*s),
           --cin => c_i(tl),
    cin   => h_c_1,
    cout  => c_i(tl+1),
    start => start_stage_i(tl+1),
    reset => reset,
          --ready => stage_ready_i(i),
    done => stage_done_i(tl+1),
    r    => r_tot((((tl+2)*s)-1) downto (s*(tl+1)))
  );
	
  stages_h : for i in (tl+2) to (t-2) generate
    standard_stages : standard_stage
    generic map(
      width => s
    )
    port map(
      core_clk => core_clk,
      my       => my(((i+1)*s) downto ((s*i)+1)),
      y        => y(((i+1)*s) downto ((s*i)+1)),
      m        => m(((i+1)*s) downto ((s*i)+1)),
      xin      => x_i(i),
      qin      => q_i(i-1),
      xout     => x_i(i+1),
      qout     => q_i(i),
      a_msb    => a_i((i+1)*s),
      cin      => c_i(i-1),
      cout     => c_i(i),
      start    => start_stage_i(i),
      reset    => reset,
          --ready => stage_ready_i(i),
      done => stage_done_i(i),
      r    => r_tot((((i+1)*s)-1) downto (s*i))
    );
  end generate;

  stage_t : last_stage
  generic map(
    width => s -- must be the same as width of the standard stage
  )
  port map(
    core_clk => core_clk,
    my       => my(n downto ((n-s)+1)),       --width-1
    y        => y((n-1) downto ((n-s)+1)),    --width-2
    m        => m((n-1) downto ((n-s)+1)),    --width-2
    xin      => x_i(t-1),
    qin      => q_i(t-2),
    cin      => c_i(t-2),
    start    => start_stage_i(t-1),
    reset    => reset,
           --ready => stage_ready_i(t-1),
    r => r_tot((n+1) downto (n-s))     --width+1
  );

  mid_start : first_stage
  generic map(
    width => s
  )
  port map(
    core_clk => core_clk,
    my       => my((tl*s+s) downto tl*s),
    y        => y((tl*s+s) downto tl*s),
    m        => m((tl*s+s) downto tl*s),
    xin      => x_i(0),
    xout     => h_x_0,
    qout     => h_q_0,
    a_msb    => a_i((tl+1)*s),
    cout     => h_c_0,
    start    => start_higher_i,
    reset    => reset,
        --ready => stage_ready_i(0),
    done => higher_0_done_i,
    r    => r_h
  );

  mid_end : last_stage
  generic map(
    width => s -- must be the same as width of the standard stage
  )
  port map(
    core_clk => core_clk,
    my       => my((tl*s) downto ((tl-1)*s)+1),       --width-1
    y        => y(((tl*s)-1) downto ((tl-1)*s)+1),    --width-2
    m        => m(((tl*s)-1) downto ((tl-1)*s)+1),    --width-2
    xin      => x_i(tl-1),
    qin      => q_i(tl-2),
    cin      => c_i(tl-2),
    start    => start_stage_i(tl-1),
    reset    => reset,
           --ready => stage_ready_i(t-1),
    r => r_l     --width+1
  );

end Structural;
