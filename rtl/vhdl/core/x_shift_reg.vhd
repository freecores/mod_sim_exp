----------------------------------------------------------------------  
----  x_shift_reg                                                 ---- 
----                                                              ---- 
----  This file is part of the                                    ----
----    Modular Simultaneous Exponentiation Core project          ---- 
----    http://www.opencores.org/cores/mod_sim_exp/               ---- 
----                                                              ---- 
----  Description                                                 ---- 
----    1536 bit shift register with lsb output                   ----
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


entity x_shift_reg is
  generic(
    n  : integer := 1536;
    t  : integer := 48;
    tl : integer := 16
  );
  port(
    clk    : in  std_logic;
    reset  : in  std_logic;
    x_in   : in  std_logic_vector((n-1) downto 0);
    load_x : in  std_logic;
    next_x : in  std_logic;
    p_sel  : in  std_logic_vector(1 downto 0);
    x_i    : out std_logic
  );
end x_shift_reg;


architecture Behavioral of x_shift_reg is
  signal x_reg_i  : std_logic_vector((n-1) downto 0); -- register
  constant s      : integer := n/t;   -- nr of stages
  constant offset : integer := s*tl;  -- calculate startbit pos of higher part of pipeline
begin

	REG_PROC: process(reset, clk)
	begin
		if reset = '1' then -- Reset, clear the register
			x_reg_i <= (others => '0');
		elsif rising_edge(clk) then
			if load_x = '1' then -- Load_x, load the register with x_in
				x_reg_i <= x_in;
			elsif next_x = '1' then  -- next_x, shift to right. LSbit gets lost and zero's are shifted in
				x_reg_i((n-2) downto 0) <= x_reg_i((n-1) downto 1);
			else -- else remember state
				x_reg_i <= x_reg_i;
			end if;
		end if;
	end process;

	with p_sel select  -- pipeline select
		x_i <= x_reg_i(offset) when "10", -- use bit at offset for high part of pipeline
				   x_reg_i(0) when others;    -- use LS bit for lower part of pipeline

end Behavioral;
