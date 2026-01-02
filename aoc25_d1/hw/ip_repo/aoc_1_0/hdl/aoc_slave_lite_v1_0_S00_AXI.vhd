library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity aoc_slave_lite_v1_0_s00_axi is
  generic (
    -- Users to add parameters here

    -- User parameters ends
    -- Do not modify the parameters beyond this line

    -- Width of S_AXI data bus
    c_s_axi_data_width : integer := 32;
    -- Width of S_AXI address bus
    c_s_axi_addr_width : integer := 5
  );
  port (
    -- Users to add ports here

    bram_dout : in    std_logic_vector(31 downto 0);
    bram_en   : out   std_logic;
    bram_addr : out   std_logic_vector(31 downto 0);
    bram_we   : out   std_logic_vector(3 downto 0);

    -- User ports ends
    -- Do not modify the ports beyond this line

    -- Global Clock Signal
    s_axi_aclk : in    std_logic;
    -- Global Reset Signal. This Signal is Active LOW
    s_axi_aresetn : in    std_logic;
    -- Write address (issued by master, acceped by Slave)
    s_axi_awaddr : in    std_logic_vector(c_s_axi_addr_width - 1 downto 0);
    -- Write channel Protection type. This signal indicates the
    -- privilege and security level of the transaction, and whether
    -- the transaction is a data access or an instruction access.
    s_axi_awprot : in    std_logic_vector(2 downto 0);
    -- Write address valid. This signal indicates that the master signaling
    -- valid write address and control information.
    s_axi_awvalid : in    std_logic;
    -- Write address ready. This signal indicates that the slave is ready
    -- to accept an address and associated control signals.
    s_axi_awready : out   std_logic;
    -- Write data (issued by master, acceped by Slave)
    s_axi_wdata : in    std_logic_vector(c_s_axi_data_width - 1 downto 0);
    -- Write strobes. This signal indicates which byte lanes hold
    -- valid data. There is one write strobe bit for each eight
    -- bits of the write data bus.
    s_axi_wstrb : in    std_logic_vector((c_s_axi_data_width / 8) - 1 downto 0);
    -- Write valid. This signal indicates that valid write
    -- data and strobes are available.
    s_axi_wvalid : in    std_logic;
    -- Write ready. This signal indicates that the slave
    -- can accept the write data.
    s_axi_wready : out   std_logic;
    -- Write response. This signal indicates the status
    -- of the write transaction.
    s_axi_bresp : out   std_logic_vector(1 downto 0);
    -- Write response valid. This signal indicates that the channel
    -- is signaling a valid write response.
    s_axi_bvalid : out   std_logic;
    -- Response ready. This signal indicates that the master
    -- can accept a write response.
    s_axi_bready : in    std_logic;
    -- Read address (issued by master, acceped by Slave)
    s_axi_araddr : in    std_logic_vector(c_s_axi_addr_width - 1 downto 0);
    -- Protection type. This signal indicates the privilege
    -- and security level of the transaction, and whether the
    -- transaction is a data access or an instruction access.
    s_axi_arprot : in    std_logic_vector(2 downto 0);
    -- Read address valid. This signal indicates that the channel
    -- is signaling valid read address and control information.
    s_axi_arvalid : in    std_logic;
    -- Read address ready. This signal indicates that the slave is
    -- ready to accept an address and associated control signals.
    s_axi_arready : out   std_logic;
    -- Read data (issued by slave)
    s_axi_rdata : out   std_logic_vector(c_s_axi_data_width - 1 downto 0);
    -- Read response. This signal indicates the status of the
    -- read transfer.
    s_axi_rresp : out   std_logic_vector(1 downto 0);
    -- Read valid. This signal indicates that the channel is
    -- signaling the required read data.
    s_axi_rvalid : out   std_logic;
    -- Read ready. This signal indicates that the master can
    -- accept the read data and response information.
    s_axi_rready : in    std_logic
  );
end entity aoc_slave_lite_v1_0_s00_axi;

architecture arch_imp of aoc_slave_lite_v1_0_s00_axi is

  signal reset  : std_logic;
  signal part1  : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal part2  : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal done_o : std_logic;

  -- AXI4LITE signals
  signal axi_awaddr  : std_logic_vector(c_s_axi_addr_width - 1 downto 0);
  signal axi_awready : std_logic;
  signal axi_wready  : std_logic;
  signal axi_bresp   : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_araddr  : std_logic_vector(c_s_axi_addr_width - 1 downto 0);
  signal axi_arready : std_logic;
  signal axi_rresp   : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;

  -- Example-specific design signals
  -- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
  -- ADDR_LSB is used for addressing 32/64 bit registers/memories
  -- ADDR_LSB = 2 for 32 bits (n downto 2)
  -- ADDR_LSB = 3 for 64 bits (n downto 3)
  constant addr_lsb          : integer := (c_s_axi_data_width / 32) + 1;
  constant opt_mem_addr_bits : integer := 2;
  ------------------------------------------------
  ---- Signals for user logic register space example
  --------------------------------------------------
  ---- Number of Slave Registers 5
  signal slv_reg0   : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal slv_reg1   : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal slv_reg2   : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal slv_reg3   : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal slv_reg4   : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal byte_index : integer;

  signal mem_logic : std_logic_vector(addr_lsb + opt_mem_addr_bits downto addr_lsb);

  -- State machine local parameters
  constant idle  : std_logic_vector(1 downto 0) := "00";
  constant raddr : std_logic_vector(1 downto 0) := "10";
  constant rdata : std_logic_vector(1 downto 0) := "11";
  constant waddr : std_logic_vector(1 downto 0) := "10";
  constant wdata : std_logic_vector(1 downto 0) := "11";
  -- State machine variables
  signal state_read  : std_logic_vector(1 downto 0);
  signal state_write : std_logic_vector(1 downto 0);

begin

  reset <= not s_axi_aresetn;
  -- I/O Connections assignments

  s_axi_awready <= axi_awready;
  s_axi_wready  <= axi_wready;
  s_axi_bresp   <= axi_bresp;
  s_axi_bvalid  <= axi_bvalid;
  s_axi_arready <= axi_arready;
  s_axi_rresp   <= axi_rresp;
  s_axi_rvalid  <= axi_rvalid;
  mem_logic     <= s_axi_awaddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) when (s_axi_awvalid = '1') else
                   axi_awaddr(addr_lsb + opt_mem_addr_bits downto addr_lsb);

  -- Implement Write state machine
  -- Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
  process (s_axi_aclk) is
  begin

    if rising_edge(s_axi_aclk) then
      if (s_axi_aresetn = '0') then
        -- asserting initial values to all 0's during reset
        axi_awready <= '0';
        axi_wready  <= '0';
        axi_bvalid  <= '0';
        axi_bresp   <= (others => '0');
        state_write <= idle;
      else

        case (state_write) is

          -- Initial state inidicating reset is done and ready to receive read/write transactions
          when idle =>

            if (s_axi_aresetn = '1') then
              axi_awready <= '1';
              axi_wready  <= '1';
              state_write <= waddr;
            else
              state_write <= state_write;
            end if;

          -- At this state, slave is ready to receive address along with corresponding control signals and first data packet. Response valid is also handled at this state
          when waddr =>

            if (s_axi_awvalid = '1' and axi_awready = '1') then
              axi_awaddr <= s_axi_awaddr;
              if (s_axi_wvalid = '1') then
                axi_awready <= '1';
                state_write <= waddr;
                axi_bvalid  <= '1';
              else
                axi_awready <= '0';
                state_write <= wdata;
                if (s_axi_bready = '1' and axi_bvalid = '1') then
                  axi_bvalid <= '0';
                end if;
              end if;
            else
              state_write <= state_write;
              if (s_axi_bready = '1' and axi_bvalid = '1') then
                axi_bvalid <= '0';
              end if;
            end if;

          -- At this state, slave is ready to receive the data packets until the number of transfers is equal to burst length
          when wdata =>

            if (s_axi_wvalid = '1') then
              state_write <= waddr;
              axi_bvalid  <= '1';
              axi_awready <= '1';
            else
              state_write <= state_write;
              if (s_axi_bready = '1' and axi_bvalid = '1') then
                axi_bvalid <= '0';
              end if;
            end if;

          -- reserved
          when others =>

            axi_awready <= '0';
            axi_wready  <= '0';
            axi_bvalid  <= '0';

        end case;

      end if;
    end if;

  end process;

  -- Implement memory mapped register select and write logic generation
  -- The write data is accepted and written to memory mapped registers when
  -- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
  -- select byte enables of slave registers while writing.
  -- These registers are cleared when reset (active low) is applied.
  -- Slave register write enable is asserted when valid address and data are available
  -- and the slave is ready to accept the write address and write data.

  process (s_axi_aclk) is
  begin

    if rising_edge(s_axi_aclk) then
      if (s_axi_aresetn = '0') then
        slv_reg0 <= (others => '0');
        slv_reg1 <= (others => '0');
        slv_reg2 <= (others => '0');
        slv_reg3 <= (others => '0');
        slv_reg4 <= (others => '0');
      else
        slv_reg2(0) <= done_o;
        slv_reg3    <= part1;
        slv_reg4    <= part2;
        if (s_axi_wvalid = '1') then

          case (mem_logic) is

            when b"000" =>

              for byte_index in 0 to (c_s_axi_data_width / 8 - 1) loop

                if (s_axi_wstrb(byte_index) = '1') then
                  -- Respective byte enables are asserted as per write strobes
                  -- slave registor 0
                  slv_reg0(byte_index * 8 + 7 downto byte_index * 8) <= s_axi_wdata(byte_index * 8 + 7 downto byte_index * 8);
                end if;

              end loop;

            when b"001" =>

              for byte_index in 0 to (c_s_axi_data_width / 8 - 1) loop

                if (s_axi_wstrb(byte_index) = '1') then
                  -- Respective byte enables are asserted as per write strobes
                  -- slave registor 1
                  slv_reg1(byte_index * 8 + 7 downto byte_index * 8) <= s_axi_wdata(byte_index * 8 + 7 downto byte_index * 8);
                end if;

              end loop;

            when others =>

              slv_reg0 <= slv_reg0;
              slv_reg1 <= slv_reg1;

          end case;

        end if;
      end if;
    end if;

  end process;

  -- Implement read state machine
  process (s_axi_aclk) is
  begin

    if rising_edge(s_axi_aclk) then
      if (s_axi_aresetn = '0') then
        -- asserting initial values to all 0's during reset
        axi_arready <= '0';
        axi_rvalid  <= '0';
        axi_rresp   <= (others => '0');
        state_read  <= idle;
      else

        case (state_read) is

          -- Initial state inidicating reset is done and ready to receive read/write transactions
          when idle =>

            if (s_axi_aresetn = '1') then
              axi_arready <= '1';
              state_read  <= raddr;
            else
              state_read <= state_read;
            end if;

          -- At this state, slave is ready to receive address along with corresponding control signals
          when raddr =>

            if (s_axi_arvalid = '1' and axi_arready = '1') then
              state_read  <= rdata;
              axi_rvalid  <= '1';
              axi_arready <= '0';
              axi_araddr  <= s_axi_araddr;
            else
              state_read <= state_read;
            end if;

          -- At this state, slave is ready to send the data packets until the number of transfers is equal to burst length
          when rdata =>

            if (axi_rvalid = '1' and s_axi_rready = '1') then
              axi_rvalid  <= '0';
              axi_arready <= '1';
              state_read  <= raddr;
            else
              state_read <= state_read;
            end if;

          -- reserved
          when others =>

            axi_arready <= '0';
            axi_rvalid  <= '0';

        end case;

      end if;
    end if;

  end process;

  -- Implement memory mapped register select and read logic generation
  s_axi_rdata <= slv_reg0 when (axi_araddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) = "000") else
                 slv_reg1 when (axi_araddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) = "001") else
                 slv_reg2 when (axi_araddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) = "010") else
                 slv_reg3 when (axi_araddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) = "011") else
                 slv_reg4 when (axi_araddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) = "100") else
                 (others => '0');

  -- Add user logic here
  dial_inst : entity work.dial
    port map (
      clk       => s_axi_aclk,
      rst       => reset,
      start     => slv_reg0(0),
      size      => slv_reg1,
      bram_dout => bram_dout,
      done_o    => done_o,
      part1_o   => part1,
      part2_o   => part2,
      bram_en   => bram_en,
      bram_addr => bram_addr,
      bram_we   => bram_we
    );

-- User logic ends

end architecture arch_imp;
