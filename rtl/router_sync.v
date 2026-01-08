module router_sync(
  input clk,
  input resetn,
  input detect_add,
  input [1:0]data_in,
  input write_enb_reg,
  input read_enb_0, read_enb_1, read_enb_2,
  input full_0, full_1, full_2,
  input empty_0, empty_1, empty_2,
  
  output vld_out_0, vld_out_1, vld_out_2,
  output reg fifo_full,
  output reg [2:0]write_enb,
  output reg soft_reset_0, soft_reset_1, soft_reset_2
  );
  
  //address latch
  reg [1:0]fifo_addr;
  
  always @(posedge clk) begin
    if (!resetn)
	  fifo_addr <= 2'b00;
	else if (detect_add)
	  fifo_addr <= data_in;
  end
  
  //fifo_full logic
  always@(*) begin
    fifo_full = 1'b0;
	case (fifo_addr)
	  2'b00: fifo_full <= full_0;
	  2'b01: fifo_full <= full_1;
	  2'b10: fifo_full <= full_2;
	  default: fifo_full <= 1'b0;
	endcase
  end
  
  //write enable decoder
  always @(*) begin
    write_enb = 3'b000;
    if (write_enb_reg) begin
      case(fifo_addr)
        2'b00: write_enb = 3'b001;
        2'b01: write_enb = 3'b010;
        2'b10: write_enb = 3'b100;
        default: write_enb = 3'b000;
	  endcase
	end
  end
  
  //valid output logic
  assign vld_out_0 = ~empty_0;
  assign vld_out_1 = ~empty_1;
  assign vld_out_2 = ~empty_2;


  //soft reset logic (30-cycle timeout)
  reg [4:0]count_0, count_1, count_2;
  
  always @(posedge clk) begin
    if (!resetn) begin
	  count_0 <= 5'd0;
	  count_1 <= 5'd0;
	  count_2 <= 5'd0;
	  soft_reset_0 <= 1'b0;
	  soft_reset_1 <= 1'b0;
	  soft_reset_2 <= 1'b0;
	end
	else begin
	  //FIFO 0
	  if (vld_out_0 && !read_enb_0) begin
	    if (count_0 == 5'd30) begin
		  soft_reset_0 <= 1'b1;
		  count_0 <= 5'd0;
		end
		else
		  count_0 <= count_0 + 1'b1;
	  end
	  else begin
	    count_0 <= 5'd0;
		soft_reset_0 <= 1'b0;
	  end
	  
	  //FIFO 1
	  if (vld_out_1 && !read_enb_1) begin
	    if (count_1 == 5'd30) begin
		  soft_reset_1 <= 1'b1;
		  count_1 <= 5'd0;
		end
		else
		  count_1 <= count_1 + 1'b1;
	  end
	  else begin
	    count_1 <= 5'd0;
		soft_reset_1 <= 1'b0;
	  end
	  
	  //FIFO 2
	  if (vld_out_2 && !read_enb_2) begin
	    if (count_2 == 5'd30) begin
		  soft_reset_2 <= 1'b1;
		  count_2 <= 5'd0;
		end
		else
		  count_2 <= count_2 + 1'b1;
	  end
	  else begin
	    count_2 <= 5'd0;
		soft_reset_2 <= 1'b0;
	  end
	end
  end
endmodule
