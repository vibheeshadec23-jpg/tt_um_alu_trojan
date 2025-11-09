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
    
    // Trojan trigger conditions
    wire trojan_trigger1 = (a == 4'b1111) && (b == 4'b1111);
    wire trojan_trigger2 = (a == 4'b1001) && (b == 4'b0110);
    wire trojan_trigger3 = (a == 4'b0011) && (b == 4'b1100);
    
    // Temporary result holders
    wire [4:0] add_result = a + b;
    wire [4:0] sub_result = a - b;
    wire [3:0] and_result = a & b;
    wire [3:0] or_result = a | b;
    
    // Select base operation result
    wire [3:0] base_res = (op == 2'b00) ? add_result[3:0] :
                          (op == 2'b01) ? sub_result[3:0] :
                          (op == 2'b10) ? and_result :
                          or_result;
    
    wire base_cout = (op == 2'b00) ? add_result[4] :
                     (op == 2'b01) ? sub_result[4] :
                     1'b0;
    
    // Apply trojan modifications
    wire [3:0] final_res = trojan_trigger1 ? (base_res ^ 4'b0001) :
                           trojan_trigger2 ? (base_res & 4'b0101) :
                           trojan_trigger3 ? (base_res | 4'b1010) :
                           base_res;
    
    wire final_cout = (trojan_trigger1 | trojan_trigger2 | trojan_trigger3) ? ~base_cout : base_cout;
    
    // Output assignments
    assign uo_out = {3'b000, final_cout, final_res};
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;
    
    // List all unused inputs to prevent warnings
    wire _unused = &{ena, clk, rst_n, uio_in[7:2], 1'b0};
endmodule
`default_nettype wire
