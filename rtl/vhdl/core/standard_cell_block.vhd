----------------------------------------------------------------------  
----  standard_cell_block                                         ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    a block of [width] cell_1b cells for use in the           ----
----    montgommery multiplier systolic array                     ----
----                                                              ----
----  Dependencies:                                               ----
----    - cell_1b                                                 ----
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


entity standard_cell_block is
  generic (
    width : integer := 16
  );
  port (
    my   : in  std_logic_vector((width-1) downto 0);
    y    : in  std_logic_vector((width-1) downto 0);
    m    : in  std_logic_vector((width-1) downto 0);
    x    : in  std_logic;
    q    : in  std_logic;
    a    : in  std_logic_vector((width-1) downto 0);
    cin  : in std_logic;
    cout : out std_logic;
    r    : out  std_logic_vector((width-1) downto 0)
  );
end standard_cell_block;


architecture Structural of standard_cell_block is
	signal carry : std_logic_vector(width downto 0);
begin
	
	carry(0) <= cin;
	
  cell_block : for i in 0 to (width-1) generate
    cells : cell_1b
    port map(
      my   => my(i),
      y    => y(i),
      m    => m(i),
      x    => x,
      q    => q,
      a    => a(i),
      cin  => carry(i),
      cout => carry(i+1),
      r    => r(i)
    );
  end generate;

	cout <= carry(width);
end Structural;
