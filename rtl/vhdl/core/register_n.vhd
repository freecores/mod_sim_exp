----------------------------------------------------------------------  
----  register_n                                                  ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    n bit register                                            ----
----    used in montgommery multiplier systolic array stages      ----            
----                                                              ---- 
----  Dependencies: none                                          ----
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

-- Xilinx primitives used
library UNISIM;
use UNISIM.VComponents.all;


entity register_n is
  generic(
    n : integer := 4
  );
  port(
    core_clk : in  std_logic;
    ce       : in  std_logic;
    reset    : in  std_logic;
    din      : in  std_logic_vector((n-1) downto 0);
    dout     : out std_logic_vector((n-1) downto 0)
  );
end register_n;


architecture Structural of register_n is
	signal dout_i : std_logic_vector((n-1) downto 0) := (others => '0');
begin
	
	dout <= dout_i;
	
  N_REGS : for i in 0 to n-1 generate
    FDCE_inst : FDCE
    generic map (
      INIT => '0'       -- Initial value of latch ('0' or '1')
    )
    port map (
      Q   => dout_i(i), -- Data output
      CLR => reset,     -- Asynchronous clear/reset input
      D   => din(i),    -- Data input
      C   => core_clk,  -- Gate input
      CE  => ce         -- Gate enable input
    );
  end generate;
	
end Structural;
