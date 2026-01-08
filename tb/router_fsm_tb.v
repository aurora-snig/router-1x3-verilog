`timescale 1ns/1ps

module router_fsm_tb;

  reg clk;
  reg resetn;

  reg [1:0]data_in;
  reg pkt_valid;
  reg fifo_full;
  reg parity_done;
  reg low_pkt_valid;
  reg soft_reset_0, soft_reset_1, soft_reset_2;
  reg fifo_empty_0, fifo_empty_1, fifo_empty_2;

  wire detect_add;
  wire lfd_state;
  wire ld_state;
  wire laf_state;
  wire write_enb_reg;
  wire busy;
  wire rst_int_reg;
  wire full_state;

  // DUT
  router_fsm dut (
    .clk(clk),
    .resetn(resetn),
    .data_in(data_in),
    .pkt_valid(pkt_valid),
    .fifo_full(fifo_full),
    .parity_done(parity_done),
    .low_pkt_valid(low_pkt_valid),
    .soft_reset_0(soft_reset_0),
    .soft_reset_1(soft_reset_1),
    .soft_reset_2(soft_reset_2),
    .fifo_empty_0(fifo_empty_0),
    .fifo_empty_1(fifo_empty_1),
    .fifo_empty_2(fifo_empty_2),
    .detect_add(detect_add),
    .lfd_state(lfd_state),
    .ld_state(ld_state),
    .laf_state(laf_state),
    .write_enb_reg(write_enb_reg),
    .busy(busy),
    .rst_int_reg(rst_int_reg),
    .full_state(full_state)
  );

  // Clock
  always #5 clk = ~clk;

  initial begin
    $dumpfile("router_fsm.vcd");
    $dumpvars(0, router_fsm_tb);

    // Init
    clk = 0;
    resetn = 0;
    pkt_valid = 0;
    data_in = 0;
    fifo_full = 0;
    parity_done = 0;
    low_pkt_valid = 0;
    soft_reset_0 = 0;
    soft_reset_1 = 0;
    soft_reset_2 = 0;
    fifo_empty_0 = 1;
    fifo_empty_1 = 1;
    fifo_empty_2 = 1;

    // Reset
    #12;
    resetn = 1;

    // ---- PACKET START (FIFO EMPTY) ----
    @(negedge clk);
    pkt_valid = 1;
    data_in = 2'b00;   // route to FIFO 0

    // LOAD_FIRST_DATA → LOAD_DATA
    repeat (2) @(negedge clk);

    // Payload
    @(negedge clk);
    pkt_valid = 1;

    // End payload → LOAD_PARITY
    @(negedge clk);
    pkt_valid = 0;

    // Parity done
    @(negedge clk);
    parity_done = 1;

    @(negedge clk);
    parity_done = 0;

    // ---- FIFO FULL SCENARIO ----
    @(negedge clk);
    pkt_valid = 1;
    fifo_full = 1;

    repeat (2) @(negedge clk);

    fifo_full = 0;

    // ---- WAIT TILL EMPTY ----
    @(negedge clk);
    fifo_empty_0 = 0;
    pkt_valid = 1;
    data_in = 2'b00;

    repeat (2) @(negedge clk);

    fifo_empty_0 = 1;

    // ---- SOFT RESET ----
    @(negedge clk);
    soft_reset_0 = 1;

    @(negedge clk);
    soft_reset_0 = 0;

    #50;
    $finish;
  end

endmodule
