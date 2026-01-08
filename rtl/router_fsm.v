module router_fsm(
  input clk,
  input resetn,
  input [1:0]data_in,
  
  input pkt_valid,
  input fifo_full,
  input parity_done,
  input low_pkt_valid,
  input soft_reset_0, soft_reset_1, soft_reset_2,
  input fifo_empty_0, fifo_empty_1, fifo_empty_2,
  
  output reg detect_add,
  output reg lfd_state,
  output reg ld_state,
  output reg laf_state,
  output reg write_enb_reg,
  output reg busy,
  output reg rst_int_reg,
  output reg full_state
  );
  
  //address latch
  reg [1:0]fifo_addr;
  
  always @(posedge clk) begin
    if (!resetn)
	  fifo_addr <= 2'b00;
	else if (detect_add)
	  fifo_addr <= data_in;
  end
  
  
  parameter DECODE_ADDRESS    = 4'd0,
            LOAD_FIRST_DATA   = 4'd1,
            LOAD_DATA         = 4'd2,
            LOAD_PARITY       = 4'd3,
            FIFO_FULL_STATE   = 4'd4,
            LOAD_AFTER_FULL   = 4'd5,
            WAIT_TILL_EMPTY   = 4'd6,
            CHECK_PARITY_ERROR= 4'd7;

  reg [3:0] state, next_state;

  
  always @(posedge clk) begin
    if (!resetn)
	  state <= DECODE_ADDRESS;
	else if (soft_reset_0 || soft_reset_1 || soft_reset_2)
	  state <= DECODE_ADDRESS;
	else
	  state <= next_state;
  end
  
  //next state logic
  always @(*) begin
    next_state = state;
	
	case (state)
	  //------------------------------------------------------------
	  DECODE_ADDRESS: begin
        if (pkt_valid) begin
          case (data_in)
            2'b00: next_state = fifo_empty_0 ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
            2'b01: next_state = fifo_empty_1 ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
            2'b10: next_state = fifo_empty_2 ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
            default: next_state = DECODE_ADDRESS;
          endcase
        end
        else
          next_state = DECODE_ADDRESS;
        end
	  
	  //------------------------------------------------------------
	  LOAD_FIRST_DATA: begin
	    next_state = LOAD_DATA;  //unconditional
	  end
	  
	  //------------------------------------------------------------
	  LOAD_DATA: begin
	    if (fifo_full)
		  next_state = FIFO_FULL_STATE;
		else if (!pkt_valid)
		  next_state = LOAD_PARITY;
		else
		  next_state = LOAD_DATA;
	  end
	  
	  //------------------------------------------------------------
	  LOAD_PARITY: begin
	    next_state = CHECK_PARITY_ERROR;
	  end
	  
	  //------------------------------------------------------------
	  FIFO_FULL_STATE: begin
	    if (!fifo_full)
		  next_state = LOAD_AFTER_FULL;
		else
		  next_state = FIFO_FULL_STATE;
	  end
	  
	  //------------------------------------------------------------
	  LOAD_AFTER_FULL: begin
	    if (parity_done)
		  next_state = DECODE_ADDRESS;
		else if (low_pkt_valid)
		  next_state = LOAD_PARITY;
		else
		  next_state = LOAD_DATA;
	  end
	  
	  //------------------------------------------------------------
      WAIT_TILL_EMPTY: begin
        case (fifo_addr)
          2'b00: next_state = fifo_empty_0 ? DECODE_ADDRESS : WAIT_TILL_EMPTY;
          2'b01: next_state = fifo_empty_1 ? DECODE_ADDRESS : WAIT_TILL_EMPTY;
          2'b10: next_state = fifo_empty_2 ? DECODE_ADDRESS : WAIT_TILL_EMPTY;
          default: next_state = DECODE_ADDRESS;
        endcase
      end
	  
	  //------------------------------------------------------------
	  CHECK_PARITY_ERROR: begin
	    if (fifo_full)
		  next_state = FIFO_FULL_STATE;
		else
		  next_state = DECODE_ADDRESS;
      end
	endcase
  end
  
  //output logic
  always @(*) begin
    
	// DEFAULTS
    detect_add    = 1'b0;
    lfd_state     = 1'b0;
    ld_state      = 1'b0;
    laf_state     = 1'b0;
    write_enb_reg = 1'b0;
    busy          = 1'b0;
    rst_int_reg   = 1'b0;
    full_state    = 1'b0;
	
    case (state)

	  //------------------------------------------------------------   
      DECODE_ADDRESS: begin
        detect_add = 1'b1;
        busy       = 1'b0;
      end

	  //------------------------------------------------------------	
	  LOAD_FIRST_DATA: begin
        lfd_state = 1'b1;
        busy      = 1'b1;
      end

	  //------------------------------------------------------------	
      LOAD_DATA: begin
        ld_state      = 1'b1;
        write_enb_reg = 1'b1;
        busy          = 1'b0;
      end

	  //------------------------------------------------------------
      LOAD_PARITY: begin
        write_enb_reg = 1'b1;
        busy          = 1'b1;
      end

	  //------------------------------------------------------------
      FIFO_FULL_STATE: begin
        busy       = 1'b1;
        full_state = 1'b1;
      end

	  //------------------------------------------------------------
      LOAD_AFTER_FULL: begin
        laf_state     = 1'b1;
        write_enb_reg = 1'b1;
        busy          = 1'b1;
      end

	  //------------------------------------------------------------
      WAIT_TILL_EMPTY: begin
        busy = 1'b1;
      end

	  //------------------------------------------------------------
      CHECK_PARITY_ERROR: begin
        rst_int_reg = 1'b1;
        busy        = 1'b1;
      end

    endcase
  end
 
endmodule