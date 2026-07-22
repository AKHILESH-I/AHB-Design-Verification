module ahb_slave(
  input HCLK, HRESET,
  input [31:0] HADDR,
  input HWRITE, 
  input [2:0] HSIZE, HBURST,
  input [1:0] HTRANS, 
  input [31:0] HWDATA,
  output reg HREADY, HRESP,
  output reg [31:0] HRDATA);
  parameter idle = 2'b00, sample_state = 2'b01, write_state = 2'b10, write_state_ready = 2'b11;
  reg [1:0] htrans_internal;
  reg hwrite_internal;
  reg [31:0] addr_internal;
  reg [1:0] ps, ns;
 //PRESENT STATE
  always @(posedge HCLK)
  begin
    if(HRESET) begin
      ps <= idle;
    end
    else
      ps <= ns;
    end
   //NEXT STATE LOGIC
    always @(*) begin
      htrans_internal = 0;
      hwrite_internal = 0;
      addr_internal = 0;
      ns = ps;
      HREADY = 1'b1;
      HRESP = 1'b0;
      HRDATA = 32'd0;
    case(ps)
      idle: begin
        HREADY = 1;
        ns = sample_state;
      end
      sample_state: begin
        htrans_internal = HTRANS;
        hwrite_internal = HWRITE;
        addr_internal = HADDR;
        if(htrans_internal == 2'b10 || htrans_internal == 2'b11)
        if(hwrite_internal)
        ns = write_state;
      end 
      write_state: begin
        HRDATA = HWDATA;
        if(htrans_internal == 2'b00)
        ns = idle;
      end
    endcase
  end
endmodule
