`timescale 1ns/1ps

module router_top_tb();

  reg clk, resetn;
  reg read_enb_0, read_enb_1, read_enb_2;
  reg pkt_valid;
  reg [7:0] data_in;

  wire [7:0] data_out_0, data_out_1, data_out_2;
  wire vld_out_0, vld_out_1, vld_out_2;
  wire err, busy;

  integer i;

  // DUT instantiation
  router_top DUT (
    .clk(clk),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .read_enb_0(read_enb_0),
    .read_enb_1(read_enb_1),
    .read_enb_2(read_enb_2),
    .data_in(data_in),
    .vld_out_0(vld_out_0),
    .vld_out_1(vld_out_1),
    .vld_out_2(vld_out_2),
    .err(err),
    .busy(busy),
    .data_out_0(data_out_0),
    .data_out_1(data_out_1),
    .data_out_2(data_out_2)
  );

  // Clock generation
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // Reset task
  task reset;
    begin
      resetn = 1'b0;
      {read_enb_0, read_enb_1, read_enb_2, pkt_valid, data_in} = 0;
      #10;
      resetn = 1'b1;
    end
  endtask

  // Packet generator – payload length 8 → output port 1
  task pktm_gen_8;
    reg [7:0] header, payload_data, parity;
    reg [5:0] payloadlen;
    begin
      parity = 0;

      wait(!busy);
      @(negedge clk);
      payloadlen = 8;
      pkt_valid  = 1'b1;
      header     = {payloadlen, 2'b01}; // DEST = 1
      data_in    = header;
      parity     = parity ^ data_in;

      @(negedge clk);

      for (i = 0; i < payloadlen; i = i + 1) begin
        wait(!busy);
        @(negedge clk);
        payload_data = $random;
        data_in      = payload_data;
        parity       = parity ^ data_in;
      end

      wait(!busy);
      @(negedge clk);
      pkt_valid = 1'b0;
      data_in   = parity;

      // 🔑 FIX: read when vld_out_1 is high
      wait (vld_out_1);
      while (vld_out_1) begin
        @(negedge clk);
        read_enb_1 = 1'b1;
        @(negedge clk);
        read_enb_1 = 1'b0;
      end
    end
  endtask


  // Packet generator – payload length 5 → output port 2
  task pktm_gen_5;
    reg [7:0] header, payload_data, parity;
    reg [5:0] payloadlen;
    begin
      parity = 0;

      wait(!busy);
      @(negedge clk);
      payloadlen = 5;
      pkt_valid  = 1'b1;
      header     = {payloadlen, 2'b10}; // DEST = 2
      data_in    = header;
      parity     = parity ^ data_in;

      @(negedge clk);

      for (i = 0; i < payloadlen; i = i + 1) begin
        wait(!busy);
        @(negedge clk);
        payload_data = $random;
        data_in      = payload_data;
        parity       = parity ^ data_in;
      end

      wait(!busy);
      @(negedge clk);
      pkt_valid = 1'b0;
      data_in   = parity;

      // 🔑 FIX: read when vld_out_2 is high
      wait (vld_out_2);
      while (vld_out_2) begin
        @(negedge clk);
        read_enb_2 = 1'b1;
        @(negedge clk);
        read_enb_2 = 1'b0;
      end
    end
  endtask


  // Test sequence
  initial begin
    $dumpfile("router_top.vcd");
    $dumpvars(0, router_top_tb);

    reset;
    #10;
    pktm_gen_8;
    pktm_gen_5;
    #1000;
    $finish;
  end

endmodule
