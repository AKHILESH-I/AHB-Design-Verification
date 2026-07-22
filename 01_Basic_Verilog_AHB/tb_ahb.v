module ahb_tb( );
  reg clk, rst;
  reg [31:0] data_top;
  reg write_top;
  reg wrap_enable;
  wire hready, hresp;
  wire [31:0] hrdata;
  reg enb;
  reg [31:0] addr_top;
  wire HWRITE;
  wire [2:0] HSIZE;
  wire [2:0] HBURST;
  wire [1:0] HTRANS;
  wire [31:0] HADDR;
  wire [31:0] HWDATA;
  reg [3:0] beat_length;

  wire fifo_empty, fifo_full;

  ahb_master DUT (.CLK_MASTER(clk), .RESET_MASTER(rst), .HREADY(hready), .HRDATA(hrdata),
    // User-defined signals
    .data_top(data_top), .write_top(write_top), .beat_length(beat_length), .enb(enb), .addr_top(addr_top), .wrap_enb(wrap_enable),
    // AHB Outputs
    .HADDR(HADDR), .HWRITE(HWRITE), .HSIZE(HSIZE), .HWDATA(HWDATA), .HBURST(HBURST), .HTRANS(HTRANS),
    // FIFO Status
    .fifo_empty  (fifo_empty), .fifo_full(fifo_full));

  ahb_slave slave(.HCLK(clk), .HRESET(rst), .HADDR(HADDR), .HWRITE(HWRITE), .HSIZE(HSIZE), .HBURST(HBURST), .HTRANS(HTRANS),
    .HWDATA(HWDATA), .HREADY(hready), .HRESP(hresp), .HRDATA(hrdata));
  initial {clk, rst, beat_length} = 0;
  always #5 clk = ~clk;
  initial begin
    rst = 1;
    #10;
    rst = 0;
    @(posedge clk);
    if(!fifo_full) begin
      write_top = 1;
      addr_top = 32'h0000_0000;
      data_top = 32'h0000_0001;
      @(posedge clk);
      data_top = 32'h1234_5678;
      @(posedge clk);
      data_top = 32'h0000_0002;
      @(posedge clk);
      data_top = 32'h0000_0003;
      beat_length = 4;
      enb = 1;
      wrap_enable = 0;
      repeat(20)
      @(posedge clk);
      enb = 0;
    end
  $finish;
  end
endmodule
