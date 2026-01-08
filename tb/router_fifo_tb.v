`timescale 1ns/1ps

module router_fifo_tb();

  // Signal declarations
  reg clk;
  reg resetn;
  reg soft_reset;
  reg write_enb;
  reg read_enb;
  reg lfd_state;
  reg [7:0]data_in;

  wire full;
  wire empty;
  wire [7:0]data_out;

  // DUT instantiation
  router_fifo DUT (
    .clk(clk),
    .resetn(resetn),
    .soft_reset(soft_reset),
    .write_enb(write_enb),
    .read_enb(read_enb),
    .lfd_state(lfd_state),
    .data_in(data_in),
    .full(full),
    .empty(empty),
    .data_out(data_out)
  );

  // Clock generation (10ns period)
  always #5 clk = ~clk;

  initial begin
    $dumpfile("router_fifo.vcd");
    $dumpvars(0, router_fifo_tb);

    // INIT
    clk        = 0;
    resetn     = 0;
    soft_reset = 0;
    write_enb  = 0;
    read_enb   = 0;
    lfd_state  = 0;
    data_in    = 0;

    // RESET
    #12;
    resetn = 1;

    // ---------------- HEADER ----------------
    @(negedge clk);
    write_enb = 1;
    lfd_state = 1;                 // header ONLY
    data_in   = {2'b00, 6'd4};      // addr=0, payload=4 bytes

    // ---------------- PAYLOAD ----------------
    @(negedge clk);
    lfd_state = 0;
    data_in   = $random;

    @(negedge clk);
    data_in   = $random;

    // ---------------- START READ EARLY ----------------
    @(negedge clk);
    read_enb = 1;
    data_in  = $random;

    @(negedge clk);
    data_in  = $random;

    // ---------------- PARITY ----------------
    @(negedge clk);
    write_enb = 0;
    data_in   = $random;

    // Continue reading
    repeat (7) begin
      @(negedge clk);
    end

    read_enb = 0;

    #50;
    $finish;
  end

endmodule