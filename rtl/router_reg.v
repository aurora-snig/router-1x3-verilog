module router_reg(
  input        clk,
  input        resetn,
  input        pkt_valid,
  input  [7:0]data_in,

  input fifo_full,
  input detect_add,
  input ld_state,
  input lfd_state,
  input laf_state,
  input full_state,
  input rst_int_reg,

  output reg err,
  output reg parity_done,
  output reg low_pkt_valid,
  output reg [7:0]dout
);

  // Internal registers
  reg [7:0] header_reg;
  reg [7:0] fifo_full_reg;
  reg [7:0] internal_parity;
  reg [7:0] packet_parity;

  // ------------------------------------------------------------
  // PARITY DONE
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (!resetn)
      parity_done <= 1'b0;
    else if (detect_add)
      parity_done <= 1'b0;
    else if (ld_state && !fifo_full && !pkt_valid)
      parity_done <= 1'b1;
    else if (laf_state && low_pkt_valid && !parity_done)
      parity_done <= 1'b1;
  end

  // ------------------------------------------------------------
  // LOW PACKET VALID
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (!resetn)
      low_pkt_valid <= 1'b0;
    else if (rst_int_reg)
      low_pkt_valid <= 1'b0;
    else if (ld_state && !pkt_valid)
      low_pkt_valid <= 1'b1;
  end

  // ------------------------------------------------------------
  // HEADER REGISTER
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (!resetn)
      header_reg <= 8'd0;
    else if (detect_add && pkt_valid)
      header_reg <= data_in;
  end

  // ------------------------------------------------------------
  // DATA OUT LOGIC
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (!resetn)
      dout <= 8'd0;
    else if (lfd_state)
      dout <= header_reg;
    else if (ld_state && !fifo_full)
      dout <= data_in;
    else if (laf_state)
      dout <= fifo_full_reg;
  end

  // ------------------------------------------------------------
  // FIFO FULL DATA HOLD
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (!resetn)
      fifo_full_reg <= 8'd0;
    else if (ld_state && fifo_full)
      fifo_full_reg <= data_in;
  end

  // ------------------------------------------------------------
  // INTERNAL PARITY
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (!resetn)
      internal_parity <= 8'd0;
    else if (detect_add)
      internal_parity <= 8'd0;
    else if (lfd_state)
      internal_parity <= internal_parity ^ header_reg;
    else if (ld_state && pkt_valid && !full_state)
      internal_parity <= internal_parity ^ data_in;
    else if (laf_state)
      internal_parity <= internal_parity ^ fifo_full_reg;
  end

  // ------------------------------------------------------------
  // PACKET PARITY BYTE
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (!resetn)
      packet_parity <= 8'd0;
    else if (!pkt_valid && ld_state)
      packet_parity <= data_in;
  end

  // ------------------------------------------------------------
  // ERROR GENERATION
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (!resetn)
      err <= 1'b0;
    else if (parity_done)
      err <= (internal_parity != packet_parity);
  end

endmodule
