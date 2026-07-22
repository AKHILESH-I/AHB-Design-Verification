module ahb_master(
  input CLK_MASTER, RESET_MASTER, HREADY,
  input [31:0] HRDATA,
// User-defined Inputs
  input [31:0] data_top,
  input write_top,
  input [3:0] beat_length,
  input enb,
  input [31:0] addr_top,
  input wrap_enb,
// AHB Outputs
  output [31:0] HADDR,
  output reg HWRITE,
  output reg [2:0] HSIZE,
  output reg [31:0] HWDATA,
  output reg [2:0] HBURST,
  output reg [1:0] HTRANS,
//USER DEFINED SIGNALS
  output fifo_empty, fifo_full);
  reg [2:0] present_state, next_state;
  reg [31:0] addr_internal;
  integer i;
  reg [3:0] count;
// fifo signals
  reg [3:0] wr_ptr, rd_ptr;
  reg [31:0] mem [15:0];
  reg hwrite_reg;
  reg [2:0]  hburst_reg;
  reg [2:0]  hsize_reg;
  reg [3:0] beat_length_reg;	
  parameter idle = 3'b000, write_state_address = 3'b001, read_state_address = 3'b010, write_state_data = 3'b011, read_state_data = 3'b100;
  assign fifo_empty = (wr_ptr == rd_ptr);
  assign fifo_full = ((wr_ptr + 1'b1) == rd_ptr);
// fifo reset logic
  always @(posedge CLK_MASTER) begin
    if(RESET_MASTER) begin
      for (i = 0; i < 16; i = i+1)
      mem[i] <= 0;
      wr_ptr <= 0;
    end
    else if(write_top && !fifo_full) begin
      mem[wr_ptr] <= data_top;
      wr_ptr <= wr_ptr + 1'b1;
    end 
  end
// FSM : Sequential Logic
  always @(posedge CLK_MASTER) begin
    if(RESET_MASTER) begin
      present_state <= idle;
      count <= 0;
      rd_ptr <= 0;
      addr_internal <= 0;
      hwrite_reg <= 0;
      hburst_reg <= 3'b000;
      hsize_reg  <= 3'b010;
      beat_length_reg <= 4'd0;
    end
    else begin
      present_state <= next_state;
      if(present_state == idle && next_state == write_state_address) begin
        hwrite_reg <= 1'b1;
        hsize_reg  <= 3'b010;
        beat_length_reg <= beat_length;
      if(beat_length == 1)
        hburst_reg <= 3'b000;
      else if(beat_length == 4)
        hburst_reg <= 3'b011;
    
        addr_internal <= addr_top;
      end
      if(present_state == idle && next_state  == write_state_address)
        count <= 0;
      else if(present_state == write_state_data && beat_length_reg == 4 &&HREADY && !wrap_enb)
      count <= count + 1'b1;
      if(present_state == write_state_data && beat_length_reg == 4 && HREADY  && !wrap_enb) begin
        rd_ptr <= rd_ptr + 1'b1;
        addr_internal <= addr_internal + 4;
      end
      if(present_state == write_state_data &&
          hburst_reg == 3'b000 &&
          HREADY) begin
          rd_ptr <= rd_ptr + 1'b1;
      end
    end
  end
// Next-State Combinational Logic
  always @(*) begin
    next_state = present_state;
      HWRITE = hwrite_reg;
      HSIZE = hsize_reg;
      HBURST = hburst_reg;
      HTRANS = 2'b00;
      HWDATA = 32'd0;
    case (present_state)
    idle: begin
      HSIZE = hsize_reg;
      HBURST = hburst_reg;
      HTRANS = 2'b00;
      HWDATA = 32'd0;
      if(write_top && HREADY && beat_length == 1 && enb && wrap_enb == 0) begin
        next_state = write_state_address;
      end
//LOGIC FOR INCR BURST
      else if(write_top && HREADY && beat_length == 4 && enb && wrap_enb == 0)
      begin
        next_state = write_state_address;
      end
    end
    write_state_address: begin
      HWRITE = 1'b1;
      if(hburst_reg == 3'b000) begin
        HTRANS = 2'b10;
        next_state = write_state_data;
      end
    else if(hburst_reg == 3'b011) begin
      HTRANS = 2'b10;
      next_state = write_state_data;
    end
    end
    write_state_data: begin
      HWRITE = hwrite_reg;
      if(hburst_reg ==3'b000) begin
        if(HREADY) begin
          next_state = idle;
          HTRANS = 2'b10;
          HWDATA = mem[rd_ptr]; 
        end
      end
//INCR 4 BURST
      else if(hburst_reg == 3'b011) begin
        if(!fifo_empty) begin
          HWDATA = mem[rd_ptr];
          HTRANS = 2'b11;
          if(count == beat_length_reg - 1)
          next_state = idle;
        else
          next_state = write_state_data;
        end
      end
    end
    default: begin
      next_state = idle;
    end
    endcase
  end
assign HADDR = addr_internal;
endmodule
