`timescale 1ns/1ps

module router_reg_tb;

  // ------------------------
  // DUT signals
  // ------------------------
  reg clk;
  reg resetn;

  reg pkt_valid;
  reg fifo_full;
  reg detect_add;
  reg ld_state;
  reg laf_state;
  reg full_state;
  reg lfd_state;
  reg rst_int_reg;

  reg [7:0]data_in;

  wire err;
  wire parity_done;
  wire low_pkt_valid;
  wire [7:0]dout;

  integer i;

  // ------------------------
  // DUT instantiation
  // ------------------------
  router_reg DUT (
    .clk(clk),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .fifo_full(fifo_full),
    .detect_add(detect_add),
    .ld_state(ld_state),
    .laf_state(laf_state),
    .full_state(full_state),
    .lfd_state(lfd_state),
    .rst_int_reg(rst_int_reg),
    .data_in(data_in),
    .err(err),
    .parity_done(parity_done),
    .low_pkt_valid(low_pkt_valid),
    .dout(dout)
  );

  // ------------------------
  // Clock generation (10 ns)
  // ------------------------
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // ------------------------
  // Synchronous reset task
  // ------------------------
  task reset;
  begin
    resetn = 1'b0;
    pkt_valid = 0;
    detect_add = 0;
    ld_state = 0;
    laf_state = 0;
    lfd_state = 0;
    fifo_full = 0;
    full_state = 0;
    rst_int_reg = 0;
    data_in = 8'd0;

    repeat (2) @(posedge clk);   // hold reset across posedges
    resetn = 1'b1;
    @(posedge clk);
  end
  endtask

  // ------------------------
  // Packet with correct parity
  // ------------------------
  task packet_ok;
    reg [7:0] header, payload, parity;
    reg [5:0] payload_len;
  begin
    @(negedge clk);
    payload_len = 6'd8;
    parity = 8'd0;

    detect_add = 1'b1;
    pkt_valid  = 1'b1;
    header     = {payload_len, 2'b10};
    data_in    = header;
    parity     = parity ^ header;

    @(negedge clk);
    detect_add = 1'b0;
    lfd_state  = 1'b1;

    for (i = 0; i < payload_len; i = i + 1) begin
      @(negedge clk);
      lfd_state = 0;
      ld_state  = 1'b1;
      payload   = $random;
      data_in   = payload;
      parity    = parity ^ payload;
    end

    @(negedge clk);
    pkt_valid = 0;
    data_in   = parity;

    @(negedge clk);
    ld_state = 0;
  end
  endtask

  // ------------------------
  // Packet with wrong parity
  // ------------------------
  task packet_bad;
    reg [7:0] header, payload, parity;
    reg [5:0] payload_len;
  begin
    @(negedge clk);
    payload_len = 6'd8;
    parity = 8'd0;

    detect_add = 1'b1;
    pkt_valid  = 1'b1;
    header     = {payload_len, 2'b10};
    data_in    = header;
    parity     = parity ^ header;

    @(negedge clk);
    detect_add = 1'b0;
    lfd_state  = 1'b1;

    for (i = 0; i < payload_len; i = i + 1) begin
      @(negedge clk);
      lfd_state = 0;
      ld_state  = 1'b1;
      payload   = $random;
      data_in   = payload;
      parity    = parity ^ payload;
    end

    @(negedge clk);
    pkt_valid = 0;
    data_in   = ~parity;   // WRONG parity

    @(negedge clk);
    ld_state = 0;
  end
  endtask

  // ------------------------
  // Test sequence
  // ------------------------
  initial begin
    $dumpfile("router_reg.vcd");
    $dumpvars(0, router_reg_tb);
    reset;

    #20;
    packet_ok();

    #120;
    packet_bad();

    #100;
    $finish;
  end

endmodule
