`default_nettype none
`timescale 1ns / 1ps
/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();
  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end
  
  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
  
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif
  
  // Replace tt_um_example with your module name:
  tt_um_example user_project (
      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );
  
  // Helper wires for ALU signals
  wire [3:0] a = ui_in[3:0];
  wire [3:0] b = ui_in[7:4];
  wire [1:0] op = uio_in[1:0];
  wire [3:0] res = uo_out[3:0];
  wire cout = uo_out[4];
  
  integer i, j, k;
  
  initial begin
    // Initialize signals
    clk = 0;
    rst_n = 0;
    ena = 1;
    ui_in = 0;
    uio_in = 0;
    
    // Release reset
    #10 rst_n = 1;
    #10;
    
    // Test all op codes and all input combinations
    for (k = 0; k < 4; k = k + 1) begin
      uio_in[1:0] = k;  // Set operation
      for (i = 15; i >= 0; i = i - 1) begin
        for (j = 15; j >= 0; j = j - 1) begin
          ui_in[3:0] = i;  // Set input A
          ui_in[7:4] = j;  // Set input B
          #10;
          
          // Display results
          $display("op=%b a=%d b=%d res=%d cout=%b", op, a, b, res, cout);
        end
      end
    end
    
    #10;
    $finish;
  end
  
  // Clock generation (if needed for synchronous designs)
  always #5 clk = ~clk;
  
endmodule
