------------------------------------------------------------------------------
-- axi_lite_test.vhd - entity/architecture pair
------------------------------------------------------------------------------
-- IMPORTANT:
-- DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
--
-- SEARCH FOR --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
--
-- TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
-- PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
-- OF THE USER_LOGIC ENTITY.
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          axi_lite_test.vhd
-- Version:           1.00.a
-- Description:       Top level design, instantiates library components and user logic.
-- Date:              Mon Mar 11 15:48:39 2013 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library mod_sim_exp;
use mod_sim_exp.mod_sim_exp_pkg;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_S_AXI_DATA_WIDTH           -- AXI4LITE slave: Data width
--   C_S_AXI_ADDR_WIDTH           -- AXI4LITE slave: Address Width
--   C_S_AXI_MIN_SIZE             -- AXI4LITE slave: Min Size
--   C_USE_WSTRB                  -- AXI4LITE slave: Write Strobe
--   C_DPHASE_TIMEOUT             -- AXI4LITE slave: Data Phase Timeout
--   C_BASEADDR                   -- AXI4LITE slave: base address
--   C_HIGHADDR                   -- AXI4LITE slave: high address
--   C_FAMILY                     -- FPGA Family
--   C_NUM_REG                    -- Number of software accessible registers
--   C_NUM_MEM                    -- Number of address-ranges
--   C_SLV_AWIDTH                 -- Slave interface address bus width
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--
-- Definition of Ports:
--   S_AXI_ACLK                   -- AXI4LITE slave: Clock 
--   S_AXI_ARESETN                -- AXI4LITE slave: Reset
--   S_AXI_AWADDR                 -- AXI4LITE slave: Write address
--   S_AXI_AWVALID                -- AXI4LITE slave: Write address valid
--   S_AXI_WDATA                  -- AXI4LITE slave: Write data
--   S_AXI_WSTRB                  -- AXI4LITE slave: Write strobe
--   S_AXI_WVALID                 -- AXI4LITE slave: Write data valid
--   S_AXI_BREADY                 -- AXI4LITE slave: Response ready
--   S_AXI_ARADDR                 -- AXI4LITE slave: Read address
--   S_AXI_ARVALID                -- AXI4LITE slave: Read address valid
--   S_AXI_RREADY                 -- AXI4LITE slave: Read data ready
--   S_AXI_ARREADY                -- AXI4LITE slave: read addres ready
--   S_AXI_RDATA                  -- AXI4LITE slave: Read data
--   S_AXI_RRESP                  -- AXI4LITE slave: Read data response
--   S_AXI_RVALID                 -- AXI4LITE slave: Read data valid
--   S_AXI_WREADY                 -- AXI4LITE slave: Write data ready
--   S_AXI_BRESP                  -- AXI4LITE slave: Response
--   S_AXI_BVALID                 -- AXI4LITE slave: Resonse valid
--   S_AXI_AWREADY                -- AXI4LITE slave: Wrte address ready
------------------------------------------------------------------------------

entity axi_lite_slave is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
        -- Multiplier parameters
    C_NR_BITS_TOTAL   : integer := 1536;
    C_NR_STAGES_TOTAL : integer := 96;
    C_NR_STAGES_LOW   : integer := 32;
    C_SPLIT_PIPELINE  : boolean := true;
    C_FIFO_DEPTH      : integer := 32;
    C_MEM_STYLE       : string  := "asym"; -- xil_prim, generic, asym are valid options
    C_DEVICE          : string  := "xilinx";    -- xilinx, altera are valid options
    
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_S_AXI_DATA_WIDTH             : integer              := 32;
    C_S_AXI_ADDR_WIDTH             : integer              := 32;
    C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
    C_HIGHADDR                     : std_logic_vector     := X"00000000"
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    --USER ports
    calc_time                     : out std_logic;
    IntrEvent                     : out std_logic;
    -------------------------
    -- AXI4lite interface
    -------------------------
    --- Global signals
    S_AXI_ACLK                     : in  std_logic;
    S_AXI_ARESETN                  : in  std_logic;
    --- Write address channel
    S_AXI_AWADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID                  : in  std_logic;
    S_AXI_AWREADY                  : out std_logic;
    --- Write data channel
    S_AXI_WDATA                    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WVALID                   : in  std_logic;
    S_AXI_WREADY                   : out std_logic;
    S_AXI_WSTRB                    : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    --- Write response channel
    S_AXI_BVALID                   : out std_logic;
    S_AXI_BREADY                   : in  std_logic;
    S_AXI_BRESP                    : out std_logic_vector(1 downto 0);
    --- Read address channel
    S_AXI_ARADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID                  : in  std_logic;
    S_AXI_ARREADY                  : out std_logic; 
    --- Read data channel
    S_AXI_RDATA                    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RVALID                   : out std_logic;
    S_AXI_RREADY                   : in  std_logic;
    S_AXI_RRESP                    : out std_logic_vector(1 downto 0)
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS      : string;
  attribute MAX_FANOUT of S_AXI_ACLK    : signal is "10000";
  attribute MAX_FANOUT of S_AXI_ARESETN : signal is "10000";
  attribute SIGIS of S_AXI_ACLK         : signal is "Clk";
  attribute SIGIS of S_AXI_ARESETN      : signal is "Rst";
end entity axi_lite_slave;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of axi_lite_slave is
  type axi_states is (addr_wait, read_state, write_state, response_state);
  signal state : axi_states;
  
  signal address : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal reset : std_logic;
  
  
  
  -- selection signals
  signal cs_array           : std_logic_vector(6 downto 0);
  signal core_selected      : std_logic;
  signal slv_reg_selected : std_logic;
  signal op_mem_selected    : std_logic;
  signal op_sel             : std_logic_vector(1 downto 0);
  signal MNO_sel            : std_logic;

  -- slave register signals
  signal slv_reg : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg_write_enable : std_logic;
  signal load_flags : std_logic;
  
  -- core interface signeals
  signal write_enable : std_logic;
  signal core_write_enable : std_logic;
  signal core_fifo_push : std_logic;
  signal core_data_out : std_logic_vector(31 downto 0);
  signal core_rw_address : std_logic_vector(8 downto 0);
  
  ------------------------------------------------------------------
  -- Signals for multiplier core interrupt
  ------------------------------------------------------------------
  signal core_interrupt                 : std_logic;
  signal core_fifo_full                 : std_logic;
  signal core_fifo_nopush               : std_logic;
  signal core_ready                     : std_logic;
  signal core_mem_collision             : std_logic;

  ------------------------------------------------------------------
  -- Signals for multiplier core control
  ------------------------------------------------------------------
  signal core_start                     : std_logic;
  signal core_exp_m                     : std_logic;
  signal core_p_sel                     : std_logic_vector(1 downto 0);
  signal core_dest_op_single            : std_logic_vector(1 downto 0);
  signal core_x_sel_single              : std_logic_vector(1 downto 0);
  signal core_y_sel_single              : std_logic_vector(1 downto 0);
  signal core_flags                     : std_logic_vector(15 downto 0);
  signal core_modulus_sel               : std_logic;
  
begin
  -- unused signals
  S_AXI_BRESP <= "00";
  S_AXI_RRESP <= "00";
  
  -- axi-lite slave state machine
  axi_slave_states : process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN='0' then -- slave reset state
        S_AXI_RVALID <= '0';
        S_AXI_BVALID <= '0';
        S_AXI_ARREADY <= '0';
        S_AXI_WREADY <= '0';
        S_AXI_AWREADY <= '0';
        state <= addr_wait;
        address <= (others=>'0');
        write_enable <= '0';
      else
        case state is
          when addr_wait => 
          -- wait for a read or write address and latch it in
            if S_AXI_ARVALID = '1' then -- read
              state <= read_state;
              address <= S_AXI_ARADDR;
              S_AXI_ARREADY <= '1';
            elsif S_AXI_AWVALID = '1' then -- write
              state <= write_state;
              address <= S_AXI_AWADDR;
              S_AXI_AWREADY <= '1';
            else
              state <= addr_wait;
            end if;
            
          when read_state =>
          -- place correct data on bus and generate valid pulse
            S_AXI_ARREADY <= '0';
            S_AXI_RVALID <= '1';
            state <= response_state;
            
          when write_state =>
          -- generate a write pulse
            S_AXI_AWREADY <= '0';
            if (S_AXI_WVALID = '1') then
              write_enable <= '1';
              S_AXI_WREADY <= '1';
              S_AXI_BVALID <= '1';
              state <= response_state;
            else 
              state <= write_state;
            end if;
            
          when response_state =>
            write_enable <= '0';
            S_AXI_WREADY <= '0';
          -- wait for response from master
            if (S_AXI_RREADY = '1') or (S_AXI_BREADY = '1') then
              S_AXI_RVALID <= '0';
              S_AXI_BVALID <= '0';
              state <= addr_wait;
            else
              state <= response_state;
            end if;
            
        end case;
      end if;
    end if;
  end process;
  
  -- place correct data on the bus
  S_AXI_RDATA <=  core_data_out when (core_selected='1') and (op_mem_selected='1') else
                  slv_reg       when (core_selected='1') and (slv_reg_selected='1') else
                  (others=>'0');
  
  -- SLAVE REG MAPPING
  -- core control signals
  reset <= not S_AXI_ARESETN;
  core_p_sel <= slv_reg(1 downto 0);
  core_dest_op_single <= slv_reg(3 downto 2);
  core_x_sel_single <= slv_reg(5 downto 4);
  core_y_sel_single <= slv_reg(7 downto 6);
  core_start <= slv_reg(8);
  core_exp_m <= slv_reg(9);
  core_modulus_sel <= slv_reg(10);
  
  -- implement slave register
  SLAVE_REG_WRITE_PROC : process( S_AXI_ACLK ) is
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        slv_reg <= (others => '0');
      elsif load_flags = '1' then
        slv_reg <= core_flags & slv_reg(15 downto 0) ;
      else
        if (slv_reg_write_enable='1') then
          slv_reg <= S_AXI_WDATA(31 downto 0);
        end if;
      end if;
    end if;
  end process SLAVE_REG_WRITE_PROC;
  
  -- interrupt and flags
  core_interrupt <= core_ready or core_mem_collision or core_fifo_full or core_fifo_nopush;
  
  FLAGS_CNTRL_PROC : process(S_AXI_ACLK, S_AXI_ARESETN) is
  begin
    if S_AXI_ARESETN = '0' then
      core_flags <= (others => '0');
      load_flags <= '0';
    elsif rising_edge(S_AXI_ACLK) then
      if core_start = '1' then
        core_flags <= (others => '0');
      else
        if core_ready = '1' then
          core_flags(15) <= '1';
        else
          core_flags(15) <= core_flags(15);
        end if;
        if core_mem_collision = '1' then
          core_flags(14) <= '1';
        else
          core_flags(14) <= core_flags(14);
        end if;
        if core_fifo_full = '1' then
          core_flags(13) <= '1';
        else
          core_flags(13) <= core_flags(13);
        end if;
        if core_fifo_nopush = '1' then
          core_flags(12) <= '1';
        else
          core_flags(12) <= core_flags(12);
        end if;
      end if;
      load_flags <= core_interrupt;
    end if;
  end process FLAGS_CNTRL_PROC;
  
  IntrEvent <= core_interrupt;
  
  -- high if general core address space is selected
  core_selected <=  '1' when address(31 downto 16)=C_BASEADDR(0 to 15) else 
                    '0';
  
  -- adress decoder
  with address(14 downto 12) select
    cs_array <= "0000001" when "000", -- M
                "0000010" when "001", -- OP0
                "0000100" when "010", -- OP1
                "0001000" when "011", -- OP2
                "0010000" when "100", -- OP3
                "0100000" when "101", -- FIFO
                "1000000" when "110", -- user reg space
                "0000000" when others;
                
  slv_reg_selected <= cs_array(6);
  slv_reg_write_enable <= write_enable and slv_reg_selected;
  
  -- high if memory space is selected
  op_mem_selected <= cs_array(0) or cs_array(1) or cs_array(2) or cs_array(3) or cs_array(4);
  
  -- operand memory singals
  MNO_sel <= cs_array(0);
  
  with cs_array(4 downto 1) select
    op_sel <=   "00" when "0001",
                "01" when "0010",
                "10" when "0100",
                "11" when "1000",
                "00" when others;
  
  core_rw_address <= MNO_sel & op_sel & address(7 downto 2);
  
  core_write_enable <= write_enable and op_mem_selected;
  
  
  -- FIFO signals
  core_fifo_push <= write_enable and cs_array(5);
  
  ------------------------------------------
  -- Exponentiation core instance
  ------------------------------------------
  msec: entity mod_sim_exp.mod_sim_exp_core
  generic map(
    C_NR_BITS_TOTAL   => C_NR_BITS_TOTAL,
    C_NR_STAGES_TOTAL => C_NR_STAGES_TOTAL,
    C_NR_STAGES_LOW   => C_NR_STAGES_LOW,
    C_SPLIT_PIPELINE  => C_SPLIT_PIPELINE,
    C_FIFO_DEPTH      => C_FIFO_DEPTH,
    C_MEM_STYLE       => C_MEM_STYLE,
    C_DEVICE          => C_DEVICE
  )
  port map(
    clk   => S_AXI_ACLK,
    reset => reset,
      -- operand memory interface (plb shared memory)
    write_enable => core_write_enable,
    data_in      => S_AXI_WDATA(31 downto 0),
    rw_address   => core_rw_address,
    data_out     => core_data_out,
    collision    => core_mem_collision,
      -- op_sel fifo interface
    fifo_din    => S_AXI_WDATA(31 downto 0),
    fifo_push   => core_fifo_push,
    fifo_full   => core_fifo_full,
    fifo_nopush => core_fifo_nopush,
      -- ctrl signals
    start          => core_start,
    exp_m          => core_exp_m,
    ready          => core_ready,
    x_sel_single   => core_x_sel_single,
    y_sel_single   => core_y_sel_single,
    dest_op_single => core_dest_op_single,
    p_sel          => core_p_sel,
    calc_time      => calc_time,
    modulus_sel    => core_modulus_sel
  );
  
end IMP;
