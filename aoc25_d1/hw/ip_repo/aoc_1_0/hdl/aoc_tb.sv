`timescale 1ns/1ps

module aoc_tb;

  // ------------------------------------------------------------------
  // Clock / reset
  // ------------------------------------------------------------------
  logic clk = 0;
  always #5 clk = ~clk;   // 100 MHz

  logic rst;
  logic start;

  // ------------------------------------------------------------------
  // DUT signals
  // ------------------------------------------------------------------
  logic [31:0] size;
  logic [31:0] bram_dout;
  logic        done_o;
  logic [31:0] part1_o;
  logic [31:0] part2_o;
  logic        bram_en;
  logic [31:0] bram_addr;
  logic [3:0]  bram_we;

  // ------------------------------------------------------------------
  // Instantiate DUT (VHDL entity)
  // ------------------------------------------------------------------
  dial dut (
    .clk       (clk),
    .rst       (rst),
    .start     (start),
    .size      (size),
    .bram_dout (bram_dout),
    .done_o    (done_o),
    .part1_o   (part1_o),
    .part2_o   (part2_o),
    .bram_en   (bram_en),
    .bram_addr (bram_addr),
    .bram_we   (bram_we)
  );

  // ------------------------------------------------------------------
  // BRAM model (1-cycle latency)
  // ------------------------------------------------------------------
  localparam int BRAM_DEPTH = 16;

  logic signed [31:0] bram_mem [0:BRAM_DEPTH-1];

  logic [31:0] bram_addr_q;
  logic        bram_en_q;

  // Register address/en to model 1-cycle latency
  always_ff @(posedge clk) begin
    bram_addr_q <= bram_addr;
    bram_en_q   <= bram_en;
  end

  // Drive data one cycle later
  always_comb begin
    if (bram_en_q) begin
      bram_dout = bram_mem[bram_addr_q[31:2]]; // byte → word address
    end else begin
      bram_dout = '0;
    end
  end

  // ------------------------------------------------------------------
  // Test sequence
  // ------------------------------------------------------------------
  initial begin
    // Initialize memory
    bram_mem[0] = -68;
    bram_mem[1] = -30;
    bram_mem[2] = 48;
    bram_mem[3] = -5;
    bram_mem[4] = 60;
    bram_mem[5] = -55;
    bram_mem[6] = -1;
    bram_mem[7] = -99;
    bram_mem[8] = 14;
    bram_mem[9] = -82;
    bram_mem[10] = -32;

    // Default inputs
    rst   = 1;
    start = 0;
    size  = 11;

    // Reset
    repeat (3) @(posedge clk);
    rst = 0;

    // Start transaction
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    // Wait for done
    wait (done_o == 1);
    @(posedge clk);

    // ----------------------------------------------------------------
    // Results
    // ----------------------------------------------------------------
    $display("--------------------------------------------------");
    $display("RESULTS:");
    $display("part1 (zero hits)    = %0d", part1_o);
    $display("part2 (zero crosses)= %0d", part2_o);
    $display("--------------------------------------------------");

    // Simple checks
    if (part1_o != 4)
      $error("part1 incorrect, expected 4");

    if (part2_o != 7)
      $error("part2 incorrect, expected 7");

    $display("TEST PASSED");
    $finish;
  end

endmodule
