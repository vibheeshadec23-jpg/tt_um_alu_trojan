`timescale 1ns / 1ps
`default_nettype none

module tb();
    // Testbench signals
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    reg ena;
    reg clk;
    reg rst_n;
    
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    
    // Instantiate the DUT (Device Under Test)
    tt_um_alu_trojan dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );
    
    // Clock generation (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // VCD dump for waveform viewing
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
    end
    
    // Test stimulus - only runs when not using cocotb
    `ifndef COCOTB_SIM
    initial begin
        // Initialize signals
        ena = 1;
        rst_n = 0;
        ui_in = 8'h00;
        uio_in = 8'h00;
        
        // Reset sequence
        #20;
        rst_n = 1;
        #10;
        
        $display("=== Starting ALU Trojan Tests ===\n");
        
        // Test 1: Normal ADD operation
        $display("Test 1: Normal ADD - 5 + 3");
        uio_in = 8'b00;        // op=ADD
        ui_in = 8'b0011_0101;  // b=3, a=5
        #10;
        $display("  Inputs: a=%d, b=%d, op=ADD", ui_in[3:0], ui_in[7:4]);
        $display("  Output: res=%d, cout=%b", uo_out[3:0], uo_out[4]);
        $display("  Expected: res=8, cout=0\n");
        
        // Test 2: Normal SUB operation
        $display("Test 2: Normal SUB - 7 - 4");
        uio_in = 8'b01;        // op=SUB
        ui_in = 8'b0100_0111;  // b=4, a=7
        #10;
        $display("  Inputs: a=%d, b=%d, op=SUB", ui_in[3:0], ui_in[7:4]);
        $display("  Output: res=%d, cout=%b", uo_out[3:0], uo_out[4]);
        $display("  Expected: res=3, cout=0\n");
        
        // Test 3: Normal AND operation
        $display("Test 3: Normal AND - 12 & 10");
        uio_in = 8'b10;        // op=AND
        ui_in = 8'b1010_1100;  // b=10, a=12
        #10;
        $display("  Inputs: a=%d, b=%d, op=AND", ui_in[3:0], ui_in[7:4]);
        $display("  Output: res=%d, cout=%b", uo_out[3:0], uo_out[4]);
        $display("  Expected: res=8, cout=0\n");
        
        // Test 4: Normal OR operation
        $display("Test 4: Normal OR - 5 | 10");
        uio_in = 8'b11;        // op=OR
        ui_in = 8'b1010_0101;  // b=10, a=5
        #10;
        $display("  Inputs: a=%d, b=%d, op=OR", ui_in[3:0], ui_in[7:4]);
        $display("  Output: res=%d, cout=%b", uo_out[3:0], uo_out[4]);
        $display("  Expected: res=15, cout=0\n");
        
        // Test 5: ADD with carry (Trojan Trigger 1)
        $display("Test 5: ADD with carry - 15 + 15 (TROJAN TRIGGER 1)");
        uio_in = 8'b00;        // op=ADD
        ui_in = 8'b1111_1111;  // b=15, a=15
        #10;
        $display("  Inputs: a=%d, b=%d, op=ADD", ui_in[3:0], ui_in[7:4]);
        $display("  Output: res=%d, cout=%b", uo_out[3:0], uo_out[4]);
        $display("  Expected (without trojan): res=14, cout=1");
        $display("  Expected (with trojan): res=15, cout=0 (TROJAN ACTIVE!)\n");
        
        // Test 6: Trojan Trigger 2 - a=9, b=6
        $display("Test 6: Trojan Trigger 2 - 9 + 6");
        uio_in = 8'b00;        // op=ADD
        ui_in = 8'b0110_1001;  // b=6, a=9
        #10;
        $display("  Inputs: a=%d, b=%d, op=ADD", ui_in[3:0], ui_in[7:4]);
        $display("  Output: res=%d, cout=%b", uo_out[3:0], uo_out[4]);
        $display("  Expected (without trojan): res=15, cout=0");
        $display("  Expected (with trojan): res=5, cout=1 (TROJAN ACTIVE!)\n");
        
        // Test 7: Trojan Trigger 3 - a=3, b=12
        $display("Test 7: Trojan Trigger 3 - 3 | 12");
        uio_in = 8'b11;        // op=OR
        ui_in = 8'b1100_0011;  // b=12, a=3
        #10;
        $display("  Inputs: a=%d, b=%d, op=OR", ui_in[3:0], ui_in[7:4]);
        $display("  Output: res=%d, cout=%b", uo_out[3:0], uo_out[4]);
        $display("  Expected (without trojan): res=15, cout=0");
        $display("  Expected (with trojan): res=15, cout=1 (TROJAN ACTIVE!)\n");
        
        // Test 8: SUB with underflow
        $display("Test 8: SUB with underflow - 3 - 5");
        uio_in = 8'b01;        // op=SUB
        ui_in = 8'b0101_0011;  // b=5, a=3
        #10;
        $display("  Inputs: a=%d, b=%d, op=SUB", ui_in[3:0], ui_in[7:4]);
        $display("  Output: res=%d, cout=%b", uo_out[3:0], uo_out[4]);
        $display("  Expected: res=14, cout=1 (underflow)\n");
        
        // Additional edge cases
        $display("Test 9: Zero operation - 0 + 0");
        uio_in = 8'b00;
        ui_in = 8'b0000_0000;
        #10;
        $display("  Output: res=%d, cout=%b\n", uo_out[3:0], uo_out[4]);
        
        $display("Test 10: All ones AND - 15 & 15 (TROJAN TRIGGER 1)");
        uio_in = 8'b10;
        ui_in = 8'b1111_1111;
        #10;
        $display("  Output: res=%d, cout=%b", uo_out[3:0], uo_out[4]);
        $display("  Expected (with trojan): res=14, cout=1 (TROJAN ACTIVE!)\n");
        
        $display("=== All Tests Complete ===");
        
        // End simulation
        #50;
        $finish;
    end
    `endif

endmodule

`default_nettype wire
