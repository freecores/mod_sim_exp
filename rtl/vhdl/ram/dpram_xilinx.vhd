--------------------------------------------------------------------------------
-- Entity: ram_xilinx
-- Date:2013-02-19  
-- Author: Dinghe     
--
-- Description ${cursor}
--------------------------------------------------------------------------------
-- 
--  correctly implemented as Block RAM, no other resources needed.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity dpram_xilinx is

  generic (
    WIDTHA      : integer := 32;
    SIZEA       : integer := 48;
    ADDRWIDTHA  : integer := 6;
    WIDTHB      : integer := 1536;
    SIZEB       : integer := 1;
    ADDRWIDTHB  : integer := 1
    );

  port (
    clkA   : in  std_logic;
    clkB   : in  std_logic;
    enB    : in  std_logic;
    weA    : in  std_logic;
    addrA  : in  std_logic_vector(ADDRWIDTHA-1 downto 0);
    addrB  : in  std_logic_vector(ADDRWIDTHB-1 downto 0);
    diA    : in  std_logic_vector(WIDTHA-1 downto 0);
    doB    : out std_logic_vector(WIDTHB-1 downto 0)
    );

end dpram_xilinx;

architecture behavioral of dpram_xilinx is

  function max(L, R: INTEGER) return INTEGER is
  begin
      if L > R then
          return L;
      else
          return R;
      end if;
  end;

  function min(L, R: INTEGER) return INTEGER is
  begin
      if L < R then
          return L;
      else
          return R;
      end if;
  end;

  function log2 (val: INTEGER) return natural is
    variable res : natural;
  begin
        for i in 0 to 31 loop
            if (val <= (2**i)) then
                res := i;
                exit;
            end if;
        end loop;
        return res;
  end function Log2;

  constant minWIDTH : integer := min(WIDTHA,WIDTHB);
  constant maxWIDTH : integer := max(WIDTHA,WIDTHB);
  constant maxSIZE  : integer := max(SIZEA,SIZEB);
  constant RATIO : integer := maxWIDTH / minWIDTH;

  -- An asymmetric RAM is modelled in a similar way as a symmetric RAM, with an
  -- array of array object. Its aspect ratio corresponds to the port with the
  -- lower data width (larger depth)
  type ramType is array (0 to maxSIZE-1) of std_logic_vector(minWIDTH-1 downto 0);

  -- You need to declare ram as a shared variable when :
  --   - the RAM has two write ports,
  --   - the RAM has only one write port whose data width is maxWIDTH
  -- In all other cases, ram can be a signal.
  signal ram : ramType := (others => (others => '0'));
  
  attribute ram_style : string;
  attribute ram_style of ram:signal is "block";
  
  signal readB : std_logic_vector(WIDTHB-1 downto 0):= (others => '0');
  signal addrB_i : std_logic_vector(ADDRWIDTHB-1 downto 0):= (others => '0');

begin

  -- port A: only write
  process (clkA)
  begin
    if rising_edge(clkA) then
      if weA = '1' then
        ram(conv_integer(addrA)) <= diA;
      end if;
    end if;
  end process;

  -- port B: only read
  process (clkB)
  begin
    if rising_edge(clkB) then
      if enB = '1' then        
        addrB_i <= addrB;
      end if;
      doB <= readB;
    end if;
  end process;
  
  ramoutput : for i in 0 to RATIO-1 generate
    readB((i+1)*minWIDTH-1 downto i*minWIDTH)
    <= ram(conv_integer(addrB_i & conv_std_logic_vector(i,log2(RATIO))));
  end generate;
  
end behavioral;