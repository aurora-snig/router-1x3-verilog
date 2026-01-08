module router_fifo (
    input        clk,
    input        resetn,
    input        soft_reset,
    input        write_enb,
    input        read_enb,
    input        lfd_state,
    input  [7:0]data_in,
	
    output reg   full,
    output reg   empty,
    output reg [7:0]data_out
);

    // FIFO memory: 16 x 9
    reg [8:0]mem[0:15];

    // Pointers
    reg [3:0]wr_ptr;
    reg [3:0]rd_ptr;

    // Occupancy counter
    reg [4:0]incrementer;

    // Packet length counter
    reg [5:0]pkt_count;

    // Header latch
    reg header_flag;

    integer i;

    //--------------------------------------------------------------------------
    // Latch lfd_state (header indicator)
    always @(posedge clk) begin
        if (!resetn)
            header_flag <= 1'b0;
        else
            header_flag <= lfd_state;
    end

    //--------------------------------------------------------------------------
    // Incrementer logic (FIFO occupancy)
    always @(posedge clk) begin
        if (!resetn)
            incrementer <= 5'd0;

        else if ((write_enb && !full) && (read_enb && !empty))
            incrementer <= incrementer;   // simultaneous read & write

        else if (write_enb && !full)
            incrementer <= incrementer + 1'b1;

        else if (read_enb && !empty)
            incrementer <= incrementer - 1'b1;
    end

    //--------------------------------------------------------------------------
    // Full & Empty logic
    always @(*) begin
        empty = (incrementer == 0);
        full  = (incrementer == 5'd16);
    end

    //--------------------------------------------------------------------------
    // FIFO WRITE logic
    always @(posedge clk) begin
        if (!resetn || soft_reset) begin
            for (i = 0; i < 16; i = i + 1)
                mem[i] <= 9'd0;
        end
        else if (write_enb && !full) begin
            mem[wr_ptr] <= {header_flag, data_in};
        end
    end

    //--------------------------------------------------------------------------
    // FIFO READ logic
    always @(posedge clk) begin
        if (!resetn)
            data_out <= 8'd0;

        else if (soft_reset)
            data_out <= 8'bz;

        else if (read_enb && !empty)
            data_out <= mem[rd_ptr][7:0];

        else if (pkt_count == 0)
            data_out <= 8'bz;
    end

    //--------------------------------------------------------------------------
    // Packet counter logic
    always @(posedge clk) begin
        if (!resetn)
            pkt_count <= 6'd0;

        else if (read_enb && !empty) begin
            if (mem[rd_ptr][8])   // Header detected
                pkt_count <= mem[rd_ptr][7:2] + 1'b1;
            else if (pkt_count != 0)
                pkt_count <= pkt_count - 1'b1;
        end
    end

    //--------------------------------------------------------------------------
    // Pointer update logic
    always @(posedge clk) begin
        if (!resetn || soft_reset) begin
            wr_ptr <= 4'd0;
            rd_ptr <= 4'd0;
        end
        else begin
            if (write_enb && !full)
                wr_ptr <= wr_ptr + 1'b1;

            if (read_enb && !empty)
                rd_ptr <= rd_ptr + 1'b1;
        end
    end

endmodule
