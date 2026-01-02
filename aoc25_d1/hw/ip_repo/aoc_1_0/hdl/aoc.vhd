library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity aoc is
  generic (
    -- Users to add parameters here

    -- User parameters ends
    -- Do not modify the parameters beyond this line

    -- Parameters of Axi Slave Bus Interface S00_AXI
    c_s00_axi_data_width : integer := 32;
    c_s00_axi_addr_width : integer := 5
  );
  port (
    -- Users to add ports here

    bram_dout : in    std_logic_vector(31 downto 0);
    bram_en   : out   std_logic;
    bram_addr : out   std_logic_vector(31 downto 0);
    bram_we   : out   std_logic_vector(3 downto 0);

    -- User ports ends
    -- Do not modify the ports beyond this line

    -- Ports of Axi Slave Bus Interface S00_AXI
    s00_axi_aclk    : in    std_logic;
    s00_axi_aresetn : in    std_logic;
    s00_axi_awaddr  : in    std_logic_vector(c_s00_axi_addr_width - 1 downto 0);
    s00_axi_awprot  : in    std_logic_vector(2 downto 0);
    s00_axi_awvalid : in    std_logic;
    s00_axi_awready : out   std_logic;
    s00_axi_wdata   : in    std_logic_vector(c_s00_axi_data_width - 1 downto 0);
    s00_axi_wstrb   : in    std_logic_vector((c_s00_axi_data_width / 8) - 1 downto 0);
    s00_axi_wvalid  : in    std_logic;
    s00_axi_wready  : out   std_logic;
    s00_axi_bresp   : out   std_logic_vector(1 downto 0);
    s00_axi_bvalid  : out   std_logic;
    s00_axi_bready  : in    std_logic;
    s00_axi_araddr  : in    std_logic_vector(c_s00_axi_addr_width - 1 downto 0);
    s00_axi_arprot  : in    std_logic_vector(2 downto 0);
    s00_axi_arvalid : in    std_logic;
    s00_axi_arready : out   std_logic;
    s00_axi_rdata   : out   std_logic_vector(c_s00_axi_data_width - 1 downto 0);
    s00_axi_rresp   : out   std_logic_vector(1 downto 0);
    s00_axi_rvalid  : out   std_logic;
    s00_axi_rready  : in    std_logic
  );
end entity aoc;

architecture arch_imp of aoc is

  -- component declaration
  component aoc_slave_lite_v1_0_s00_axi is
    generic (
      c_s_axi_data_width : integer  := 32;
      c_s_axi_addr_width : integer  := 5
    );
    port (
      bram_dout     : in    std_logic_vector(31 downto 0);
      bram_en       : out   std_logic;
      bram_addr     : out   std_logic_vector(31 downto 0);
      bram_we       : out   std_logic_vector(3 downto 0);
      s_axi_aclk    : in    std_logic;
      s_axi_aresetn : in    std_logic;
      s_axi_awaddr  : in    std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
      s_axi_awprot  : in    std_logic_vector(2 downto 0);
      s_axi_awvalid : in    std_logic;
      s_axi_awready : out   std_logic;
      s_axi_wdata   : in    std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
      s_axi_wstrb   : in    std_logic_vector((C_S_AXI_DATA_WIDTH / 8) - 1 downto 0);
      s_axi_wvalid  : in    std_logic;
      s_axi_wready  : out   std_logic;
      s_axi_bresp   : out   std_logic_vector(1 downto 0);
      s_axi_bvalid  : out   std_logic;
      s_axi_bready  : in    std_logic;
      s_axi_araddr  : in    std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
      s_axi_arprot  : in    std_logic_vector(2 downto 0);
      s_axi_arvalid : in    std_logic;
      s_axi_arready : out   std_logic;
      s_axi_rdata   : out   std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
      s_axi_rresp   : out   std_logic_vector(1 downto 0);
      s_axi_rvalid  : out   std_logic;
      s_axi_rready  : in    std_logic
    );
  end component aoc_slave_lite_v1_0_s00_axi;

begin

  -- Instantiation of Axi Bus Interface S00_AXI
  aoc_slave_lite_v1_0_s00_axi_inst : component aoc_slave_lite_v1_0_s00_axi
    generic map (
      c_s_axi_data_width => c_s00_axi_data_width,
      c_s_axi_addr_width => c_s00_axi_addr_width
    )
    port map (
      bram_dout     => bram_dout,
      bram_en       => bram_en,
      bram_addr     => bram_addr,
      bram_we       => bram_we,
      s_axi_aclk    => s00_axi_aclk,
      s_axi_aresetn => s00_axi_aresetn,
      s_axi_awaddr  => s00_axi_awaddr,
      s_axi_awprot  => s00_axi_awprot,
      s_axi_awvalid => s00_axi_awvalid,
      s_axi_awready => s00_axi_awready,
      s_axi_wdata   => s00_axi_wdata,
      s_axi_wstrb   => s00_axi_wstrb,
      s_axi_wvalid  => s00_axi_wvalid,
      s_axi_wready  => s00_axi_wready,
      s_axi_bresp   => s00_axi_bresp,
      s_axi_bvalid  => s00_axi_bvalid,
      s_axi_bready  => s00_axi_bready,
      s_axi_araddr  => s00_axi_araddr,
      s_axi_arprot  => s00_axi_arprot,
      s_axi_arvalid => s00_axi_arvalid,
      s_axi_arready => s00_axi_arready,
      s_axi_rdata   => s00_axi_rdata,
      s_axi_rresp   => s00_axi_rresp,
      s_axi_rvalid  => s00_axi_rvalid,
      s_axi_rready  => s00_axi_rready
    );

-- Add user logic here

-- User logic ends

end architecture arch_imp;
