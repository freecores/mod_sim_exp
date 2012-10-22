----------------------------------------------------------------------  
----  adder_n                                                     ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    This file contains the implementation of a n-bit adder    ----
----    using adder_blocks                                        ----
----    used for the montgommery multiplier pre- and post-        ----
----    computation adder                                         ---- 
----                                                              ---- 
----  Dependencies:                                               ---- 
----   - adder_block                                              ---- 
----                                                              ---- 
----  Author(s):                                                  ----
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


entity adder_n is
  generic (
    width       : integer := 1536;
    block_width : integer := 8
  );
  port (
    core_clk : in std_logic;
    a        : in std_logic_vector((width-1) downto 0);
    b        : in std_logic_vector((width-1) downto 0);
    cin      : in std_logic;
    cout     : out std_logic;
    s        : out std_logic_vector((width-1) downto 0)
  );
end adder_n;


architecture Structural of adder_n is
  constant nr_of_blocks : integer := width/block_width;
  signal carry : std_logic_vector(nr_of_blocks downto 0);
begin

  carry(0) <= cin;

  adder_block_chain : for i in 0 to (nr_of_blocks-1) generate
    adder_blocks : adder_block
    generic map(
      width => block_width
    )
    port map(
      core_clk => core_clk,
      a        => a((((i+1)*block_width)-1) downto (i*block_width)),
      b        => b((((i+1)*block_width)-1) downto (i*block_width)),
      cin      => carry(i),
      cout     => carry(i+1),
      s        => s((((i+1)*block_width)-1) downto (i*block_width))
    );
  end generate;

  cout <= carry(nr_of_blocks);

end Structural;