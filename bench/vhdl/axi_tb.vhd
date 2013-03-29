--------------------------------------------------------------------------------
-- Entity: axi_tb
-- Date:2013-03-26  
-- Author: Dinghe     
--
-- Description ${cursor}
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_textio.all;

entity axi_tb is
end axi_tb;

architecture arch of axi_tb is
  -- constants
  constant CLK_PERIOD : time := 10 ns;
  constant C_S_AXI_DATA_WIDTH : integer := 32;
  constant C_S_AXI_ADDR_WIDTH : integer := 32;
  
  file output : text open write_mode is "out/axi_output.txt";

  -------------------------
  -- AXI4lite interface
  -------------------------
  --- Global signals
  signal S_AXI_ACLK    : std_logic;
  signal S_AXI_ARESETN : std_logic;
  --- Write address channel
  signal S_AXI_AWADDR  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal S_AXI_AWVALID : std_logic;
  signal S_AXI_AWREADY : std_logic;
  --- Write data channel
  signal S_AXI_WDATA  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal S_AXI_WVALID : std_logic;
  signal S_AXI_WREADY : std_logic;
  signal S_AXI_WSTRB  : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
  --- Write response channel
  signal S_AXI_BVALID : std_logic;
  signal S_AXI_BREADY : std_logic;
  signal S_AXI_BRESP  : std_logic_vector(1 downto 0);
  --- Read address channel
  signal S_AXI_ARADDR  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal S_AXI_ARVALID : std_logic;
  signal S_AXI_ARREADY : std_logic;
  --- Read data channel
  signal S_AXI_RDATA  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal S_AXI_RVALID : std_logic;
  signal S_AXI_RREADY : std_logic;
  signal S_AXI_RRESP  : std_logic_vector(1 downto 0);

begin

  ------------------------------------------
  -- Generate clk
  ------------------------------------------
  clk_process : process
  begin
    while (true) loop
      S_AXI_ACLK <= '0';
      wait for CLK_PERIOD/2;
      S_AXI_ACLK <= '1';
      wait for CLK_PERIOD/2;
    end loop;
  end process;


  stim_proc : process
  
    variable Lw : line;
  
    procedure waitclk(n : natural := 1) is
    begin
      for i in 1 to n loop
        wait until rising_edge(S_AXI_ACLK);
      end loop;
    end waitclk;
    
    procedure axi_write( address : std_logic_vector(31 downto 0);
                         data    : std_logic_vector(31 downto 0) ) is 
      variable counter : integer := 0;
    begin
      -- place address on the bus
      wait until rising_edge(S_AXI_ACLK);
      S_AXI_AWADDR <= address;
      S_AXI_AWVALID <= '1';
      S_AXI_WDATA <= data;
      S_AXI_WVALID <= '1';
      S_AXI_WSTRB <= "1111";
      while (counter /= 2) loop -- wait for slave response
        wait until rising_edge(S_AXI_ACLK); 
        if (S_AXI_AWREADY='1') then
          S_AXI_AWVALID <= '0';
          counter := counter+1;
        end if;
        if (S_AXI_WREADY='1') then
          S_AXI_WVALID <= '0';
          counter := counter+1;
        end if;
      end loop;
      S_AXI_BREADY <= '1';
      if S_AXI_BVALID/='1' then
        wait until S_AXI_BVALID='1';
      end if;
      
      write(Lw, string'("Wrote "));
      hwrite(Lw, data);
      write(Lw, string'(" to   "));
      hwrite(Lw, address);
      
      if (S_AXI_BRESP /= "00") then
        write(Lw, string'("   --> Error! Status: "));
        write(Lw, S_AXI_BRESP);
      end if;
      writeline(output, Lw);
      
      wait until rising_edge(S_AXI_ACLK);
      S_AXI_BREADY <= '0';
    end axi_write;
    
    procedure axi_read( address  : std_logic_vector(31 downto 0) ) is 
    begin
      -- place address on the bus
      wait until rising_edge(S_AXI_ACLK);
      S_AXI_ARADDR <= address;
      S_AXI_ARVALID <= '1';
      wait until S_AXI_ARREADY='1';
      wait until rising_edge(S_AXI_ACLK); 
      S_AXI_ARVALID <= '0';
      -- wait for read data
      S_AXI_RREADY <= '1';
      wait until S_AXI_RVALID='1';
      wait until rising_edge(S_AXI_ACLK);
      
      write(Lw, string'("Read  "));
      hwrite(Lw, S_AXI_RDATA);
      write(Lw, string'(" from "));
      hwrite(Lw, address);
      
      if (S_AXI_RRESP /= "00") then
        write(Lw, string'("   --> Error! Status: "));
        write(Lw, S_AXI_RRESP);
      end if;
      writeline(output, Lw); 
      S_AXI_RREADY <= '0';
  
      --assert false report "Wrote " & " to " & " Status=" & to_string(S_AXI_BRESP) severity note;
    end axi_read;
    
 
  begin
  
    write(Lw, string'("----------------------------------------------"));
    writeline(output, Lw);
    write(Lw, string'("--            AXI BUS SIMULATION            --"));
    writeline(output, Lw);
    write(Lw, string'("----------------------------------------------"));
    writeline(output, Lw);
    S_AXI_AWADDR <= (others=>'0');
    S_AXI_AWVALID <= '0';
    S_AXI_WDATA <= (others=>'0');
    S_AXI_WVALID <= '0';
    S_AXI_WSTRB <= (others=>'0');
    S_AXI_BREADY <= '0';
    S_AXI_ARADDR <= (others=>'0');
    S_AXI_ARVALID <= '0';
    S_AXI_RREADY <= '0';
    
    S_AXI_ARESETN <= '0';
    waitclk(10);
    S_AXI_ARESETN <= '1';
    waitclk(20);
    
    axi_write(x"A0000000", x"11111111");
    axi_read(x"A0000000");
    axi_write(x"A0001000", x"01234567");
    axi_read(x"A0001000");
    axi_write(x"A0002000", x"AAAAAAAA");
    axi_read(x"A0002000");
    axi_write(x"A0003000", x"BBBBBBBB");
    axi_read(x"A0003000");
    axi_write(x"A0004000", x"CCCCCCCC");
    axi_read(x"A0004000");
    axi_write(x"A0005000", x"DDDDDDDD");
    axi_read(x"A0005000");
    axi_write(x"A0006000", x"EEEEEEEE");
    axi_read(x"A0006000");
    waitclk(100);
    
    assert false report "End of simulation" severity failure;
    
  end process;


  -------------------------
  -- Unit Under Test
  -------------------------
  uut : entity work.axi_lite_slave
  generic map(
    C_BASEADDR => x"A0000000",
    C_HIGHADDR => x"A000FFFF"
  )
  port map(
    --USER ports

    -------------------------
    -- AXI4lite interface
    -------------------------
    --- Global signals
    S_AXI_ACLK    => S_AXI_ACLK,
    S_AXI_ARESETN => S_AXI_ARESETN,
    --- Write address channel
    S_AXI_AWADDR  => S_AXI_AWADDR,
    S_AXI_AWVALID => S_AXI_AWVALID,
    S_AXI_AWREADY => S_AXI_AWREADY,
    --- Write data channel
    S_AXI_WDATA  => S_AXI_WDATA,
    S_AXI_WVALID => S_AXI_WVALID,
    S_AXI_WREADY => S_AXI_WREADY,
    S_AXI_WSTRB  => S_AXI_WSTRB,
    --- Write response channel
    S_AXI_BVALID => S_AXI_BVALID,
    S_AXI_BREADY => S_AXI_BREADY,
    S_AXI_BRESP  => S_AXI_BRESP,
    --- Read address channel
    S_AXI_ARADDR  => S_AXI_ARADDR,
    S_AXI_ARVALID => S_AXI_ARVALID,
    S_AXI_ARREADY => S_AXI_ARREADY,
    --- Read data channel
    S_AXI_RDATA  => S_AXI_RDATA,
    S_AXI_RVALID => S_AXI_RVALID,
    S_AXI_RREADY => S_AXI_RREADY,
    S_AXI_RRESP  => S_AXI_RRESP
  );

end arch;

