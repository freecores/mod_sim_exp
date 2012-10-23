----------------------------------------------------------------------  
----  standard_stage                                              ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    standard stage for use in the montgommery multiplier      ----
----    systolic array pipeline                                   ----
----                                                              ----
----  Dependencies:                                               ----
----    - standard_cell_block                                     ----
----    - d_flip_flop                                             ----
----    - register_n                                              ----
----    - register_1b                                             ----
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


entity standard_stage is
  generic(
    width : integer := 32
  );
  port(
    core_clk : in  std_logic;
    my       : in  std_logic_vector((width-1) downto 0);
    y        : in  std_logic_vector((width-1) downto 0);
    m        : in  std_logic_vector((width-1) downto 0);
    xin      : in  std_logic;
    qin      : in  std_logic;
    xout     : out std_logic;
    qout     : out std_logic;
    a_msb    : in  std_logic;
    cin      : in  std_logic;
    cout     : out std_logic;
    start    : in  std_logic;
    reset    : in  std_logic;
    done : out std_logic;
    r    : out std_logic_vector((width-1) downto 0)
  );
end standard_stage;


architecture Structural of standard_stage is
  -- input
  signal cin_i   : std_logic;
  signal xin_i   : std_logic;
  signal qin_i   : std_logic;
  signal a_msb_i : std_logic;

  -- output
  signal cout_i     : std_logic;
  signal r_i        : std_logic_vector((width-1) downto 0);
  signal cout_reg_i : std_logic;
  signal xout_reg_i : std_logic;
  signal qout_reg_i : std_logic;
  signal r_reg_i    : std_logic_vector((width-1) downto 0);

  -- interconnect
  signal a_i : std_logic_vector((width-1) downto 0);

  -- control
  signal done_i : std_logic := '1';
begin

	-- map internal signals to outputs
	done <= done_i;
	r <= r_reg_i;
	cout <= cout_reg_i;
	qout <= qout_reg_i;
	xout <= xout_reg_i;
	
	-- map inputs to internal signals
	xin_i <= xin;
	qin_i <= qin;
	cin_i <= cin;
	a_msb_i <= a_msb;
	
	a_i <= a_msb_i & r_reg_i((width-1) downto 1);
	
  cell_block : standard_cell_block
  generic map(
    width => width
  )
  port map(
    my   => my,
    y    => y,
    m    => m,
    x    => xin_i,
    q    => qin_i,
    a    => a_i,
    cin  => cin_i,
    cout => cout_i,
    r    => r_i
  );
	
  done_signal : d_flip_flop
  port map(
    core_clk => core_clk,
    reset    => reset,
    din  => start,
    dout => done_i
  );

  -- output registers
  RESULT_REG : register_n
  generic map(
    width => width
  )
  port map(
    core_clk => core_clk,
    ce    => start,
    reset => reset,
    din   => r_i,
    dout  => r_reg_i
  );

  XOUT_REG : register_1b
  port map(
    core_clk => core_clk,
    ce    => start,
    reset => reset,
    din  => xin_i,
    dout => xout_reg_i
  );

  QOUT_REG : register_1b
  port map(
    core_clk => core_clk,
    ce    => start,
    reset => reset,
    din  => qin_i,
    dout => qout_reg_i
  );

  COUT_REG : register_1b
  port map(
    core_clk => core_clk,
    ce    => start,
    reset => reset,
    din   => cout_i,
    dout  => cout_reg_i
  );

	
end Structural;