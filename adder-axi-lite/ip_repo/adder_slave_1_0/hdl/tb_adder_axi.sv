`timescale 1ns / 1ps

module tb_axi_adder;

  // --------------------------------------------------
  // Parameters
  // --------------------------------------------------
  localparam int ADDR_WIDTH = 4;
  localparam int DATA_WIDTH = 32;

  // --------------------------------------------------
  // Clock & reset
  // --------------------------------------------------
  logic S_AXI_ACLK;
  logic S_AXI_ARESETN;

  // --------------------------------------------------
  // AXI write address channel
  // --------------------------------------------------
  logic [ADDR_WIDTH-1:0] S_AXI_AWADDR;
  logic                  S_AXI_AWVALID;
  logic                  S_AXI_AWREADY;

  // --------------------------------------------------
  // AXI write data channel
  // --------------------------------------------------
  logic [DATA_WIDTH-1:0] S_AXI_WDATA;
  logic [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB;
  logic                  S_AXI_WVALID;
  logic                  S_AXI_WREADY;

  // --------------------------------------------------
  // AXI write response channel
  // --------------------------------------------------
  logic [1:0]            S_AXI_BRESP;
  logic                  S_AXI_BVALID;
  logic                  S_AXI_BREADY;

  // --------------------------------------------------
  // AXI read address channel
  // --------------------------------------------------
  logic [ADDR_WIDTH-1:0] S_AXI_ARADDR;
  logic                  S_AXI_ARVALID;
  logic                  S_AXI_ARREADY;

  // --------------------------------------------------
  // AXI read data channel
  // --------------------------------------------------
  logic [DATA_WIDTH-1:0] S_AXI_RDATA;
  logic [1:0]            S_AXI_RRESP;
  logic                  S_AXI_RVALID;
  logic                  S_AXI_RREADY;

  // --------------------------------------------------
  // Clock generation (100 MHz)
  // --------------------------------------------------
  always #5 S_AXI_ACLK = ~S_AXI_ACLK;

  // --------------------------------------------------
  // DUT
  // --------------------------------------------------
  adder_slave_slave_lite_v1_0_S00_AXI dut (
    .S_AXI_ACLK    (S_AXI_ACLK),
    .S_AXI_ARESETN (S_AXI_ARESETN),

    .S_AXI_AWADDR  (S_AXI_AWADDR),
    .S_AXI_AWVALID (S_AXI_AWVALID),
    .S_AXI_AWREADY (S_AXI_AWREADY),

    .S_AXI_WDATA   (S_AXI_WDATA),
    .S_AXI_WSTRB   (S_AXI_WSTRB),
    .S_AXI_WVALID  (S_AXI_WVALID),
    .S_AXI_WREADY  (S_AXI_WREADY),

    .S_AXI_BRESP   (S_AXI_BRESP),
    .S_AXI_BVALID  (S_AXI_BVALID),
    .S_AXI_BREADY  (S_AXI_BREADY),

    .S_AXI_ARADDR  (S_AXI_ARADDR),
    .S_AXI_ARVALID (S_AXI_ARVALID),
    .S_AXI_ARREADY (S_AXI_ARREADY),

    .S_AXI_RDATA   (S_AXI_RDATA),
    .S_AXI_RRESP   (S_AXI_RRESP),
    .S_AXI_RVALID  (S_AXI_RVALID),
    .S_AXI_RREADY  (S_AXI_RREADY)
  );

  // --------------------------------------------------
  // AXI write task
  // --------------------------------------------------
  task automatic axi_write (
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data
  );
    begin
      @(posedge S_AXI_ACLK);
      S_AXI_AWADDR  <= addr;
      S_AXI_AWVALID <= 1'b1;
      S_AXI_WDATA   <= data;
      S_AXI_WSTRB   <= '1;
      S_AXI_WVALID  <= 1'b1;
      S_AXI_BREADY  <= 1'b1;

      wait (S_AXI_AWREADY && S_AXI_WREADY);
      @(posedge S_AXI_ACLK);

      S_AXI_AWVALID <= 1'b0;
      S_AXI_WVALID  <= 1'b0;

      wait (S_AXI_BVALID);
      @(posedge S_AXI_ACLK);
      S_AXI_BREADY <= 1'b0;
    end
  endtask

  // --------------------------------------------------
  // AXI read task
  // --------------------------------------------------
  task automatic axi_read (
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data
  );
    begin
      @(posedge S_AXI_ACLK);
      S_AXI_ARADDR  <= addr;
      S_AXI_ARVALID <= 1'b1;
      S_AXI_RREADY  <= 1'b1;

      wait (S_AXI_ARREADY);
      @(posedge S_AXI_ACLK);
      S_AXI_ARVALID <= 1'b0;

      wait (S_AXI_RVALID);
      data = S_AXI_RDATA;

      @(posedge S_AXI_ACLK);
      S_AXI_RREADY <= 1'b0;
    end
  endtask

  // --------------------------------------------------
  // Test sequence
  // --------------------------------------------------
  logic [31:0] sum;

  initial begin
    // Init
    S_AXI_ACLK    = 1'b0;
    S_AXI_ARESETN = 1'b0;

    S_AXI_AWADDR  = '0;
    S_AXI_AWVALID = 1'b0;
    S_AXI_WDATA   = '0;
    S_AXI_WVALID  = 1'b0;
    S_AXI_WSTRB   = '0;
    S_AXI_BREADY  = 1'b0;

    S_AXI_ARADDR  = '0;
    S_AXI_ARVALID = 1'b0;
    S_AXI_RREADY  = 1'b0;

    // Reset
    repeat (5) @(posedge S_AXI_ACLK);
    S_AXI_ARESETN = 1'b1;

    // Write operands
    axi_write('h00, 32'd10);
    axi_write('h04, 32'd32);

    // Read result
    axi_read('h08, sum);

    $display("SUM = %0d", sum);

    if (sum == 32'd42)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");

    #50;
    $finish;
  end

endmodule