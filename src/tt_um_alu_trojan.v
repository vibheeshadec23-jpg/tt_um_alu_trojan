/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none

module tt_um_alu_trojan (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    // Input mapping
    wire [3:0] a = ui_in[3:0];      // 4-bit input A from ui_in[3:0]
    wire [3:0] b = ui_in[7:4];      // 4-bit input B from ui_in[7:4]
    wire [1:0] op = uio_in[1:0];    // 2-bit operation selector from uio_in[1:0]
    
    // Output signals
    wire [3:0] res;
    wire cout;
    
    // Trojan trigger conditions
    wire trojan_trigger1, trojan_trigger2, trojan_trigger3;
    
    assign trojan_trigger1 = (a == 4'b1111) && (b == 4'b1111);
    assign trojan_trigger2 = (a == 4'b1001) && (b == 4'b0110);
    assign trojan_trigger3 = (a == 4'b0011) && (b == 4'b1100);
    
    // Temporary result holders
    wire [3:0] temp_res;
    wire [4:0] temp_val;
    wire temp_cout;
    
    // Calculate base operation results
    assign temp_val = (op == 2'b00) ? (a + b) :           // ADD
                      (op == 2'b01) ? (a - b) :           // SUB
                      5'b0;                                // For AND/OR (not used)
    
    assign temp_res = (op == 2'b00) ? temp_val[3:0] :     // ADD result
                      (op == 2'b01) ? temp_val[3:0] :     // SUB result
                      (op == 2'b10) ? (a & b) :           // AND
                      (a | b);                            // OR (default)
    
    assign temp_cout = (op == 2'b00) ? temp_val[4] :      // ADD carry
                       (op == 2'b01) ? temp_val[4] :      // SUB borrow
                       1'b0;                               // No carry for logical ops
    
    // Apply trojan modifications
    assign res = trojan_trigger1 ? (temp_res ^ 4'b0001) :
                 trojan_trigger2 ? (temp_res & 4'b0101) :
                 trojan_trigger3 ? (temp_res | 4'b1010) :
                 temp_res;
    
    assign cout = trojan_trigger1 ? ~temp_cout :
                  trojan_trigger2 ? ~temp_cout :
                  trojan_trigger3 ? ~temp_cout :
                  temp_cout;
    
    // Output assignments
    assign uo_out = {3'b000, cout, res};  // uo_out[3:0] = res, uo_out[4] = cout
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;
    
    // List all unused inputs to prevent warnings
    wire _unused = &{ena, clk, rst_n, uio_in[7:2], 1'b0};

endmodule

`default_nettype wire
