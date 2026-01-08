`timescale 1ns/1ps

module router_sync_tb;

  reg clk;
  reg resetn;
  reg detect_add;
  reg [1:0]data_in;
  reg write_enb_reg;

  reg read_enb_0, read_enb_1, read_enb_2;
  reg full_0, full_1, full_2;
  reg empty_0, empty_1, empty_2;

  wire vld_out_0, vld_out_1, vld_out_2;
  wire fifo_full;
  wire [2:0] write_enb;
  wire soft_reset_0, soft_reset_1, soft_reset_2;

  // DUT instantiation
  router_sync DUT (
    .clk(clk),
    .resetn(resetn),
    .detect_add(detect_add),
    .data_in(data_in),
    .write_enb_reg(write_enb_reg),
    .read_enb_0(read_enb_0),
    .read_enb_1(read_enb_1),
    .read_enb_2(read_enb_2),
    .full_0(full_0),
    .full_1(full_1),
    .full_2(full_2),
    .empty_0(empty_0),
    .empty_1(empty_1),
    .empty_2(empty_2),
    .vld_out_0(vld_out_0),
    .vld_out_1(vld_out_1),
    .vld_out_2(vld_out_2),
    .fifo_full(fifo_full),
    .write_enb(write_enb),
    .soft_reset_0(soft_reset_0),
    .soft_reset_1(soft_reset_1),
    .soft_reset_2(soft_reset_2)
  );

  // Clock: 10ns
  always #5 clk = ~clk;

  initial begin
    $dumpfile("router_sync.vcd");
    $dumpvars(0, router_sync_tb);

    // RESET
    clk = 0;
    resetn = 0;

    detect_add = 0;
    data_in = 2'b00;
    write_enb_reg = 0;

    read_enb_0 = 0; read_enb_1 = 0; read_enb_2 = 0;
    full_0 = 0; full_1 = 0; full_2 = 0;
    empty_0 = 1; empty_1 = 1; empty_2 = 1;

    #12;                 // cross negedge
    resetn = 1;

    // SELECT FIFO 1
    @(negedge clk);
    detect_add = 1;
    data_in = 2'b01;

    @(negedge clk);
    detect_add = 0;

    // WRITE ENABLE
    @(negedge clk);
    write_enb_reg = 1;
    empty_1 = 0;         // FIFO 1 has data now

    repeat (3) @(posedge clk); // observe write_enb

    @(negedge clk);
    write_enb_reg = 0;

    // READ START
    @(negedge clk);
    read_enb_1 = 1;

    repeat (2) @(posedge clk);

    @(negedge clk);
    read_enb_1 = 0;
    empty_1 = 1;

    // SOFT RESET CHECK (FIFO 2)
    @(negedge clk);
    detect_add = 1;
    data_in = 2'b10;

    @(negedge clk);
    detect_add = 0;
    empty_2 = 0;         // vld_out_2 goes high

    // No read_enb_2 → should trigger soft_reset_2
    repeat (31) @(posedge clk);
    
	#50
    $finish;
  end

endmodule
