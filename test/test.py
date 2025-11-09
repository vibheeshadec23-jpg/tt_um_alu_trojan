# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    
    dut._log.info("Test ALU project behavior")
    
    # Test all operations and all input combinations
    for op in range(4):
        dut._log.info(f"Testing operation {op}: {['ADD', 'SUB', 'AND', 'OR'][op]}")
        dut.uio_in.value = op  # Set operation code
        
        for a in range(16):
            for b in range(16):
                # Set input values
                dut.ui_in.value = (b << 4) | a  # ui_in[7:4] = b, ui_in[3:0] = a
                
                # Wait for one clock cycle to see the output values
                await ClockCycles(dut.clk, 1)
                
                # Extract result and carry from output
                result = dut.uo_out.value & 0x0F  # uo_out[3:0]
                cout = (dut.uo_out.value >> 4) & 0x01  # uo_out[4]
                
                # Calculate expected values
                if op == 0:  # ADD
                    temp = a + b
                    expected_res = temp & 0x0F
                    expected_cout = (temp >> 4) & 0x01
                elif op == 1:  # SUB
                    temp = (a - b) & 0x1F
                    expected_res = temp & 0x0F
                    expected_cout = (temp >> 4) & 0x01
                elif op == 2:  # AND
                    expected_res = a & b
                    expected_cout = 0
                elif op == 3:  # OR
                    expected_res = a | b
                    expected_cout = 0
                
                # Check for trojan trigger conditions
                trojan_trigger1 = (a == 15) and (b == 15)
                trojan_trigger2 = (a == 9) and (b == 6)
                trojan_trigger3 = (a == 3) and (b == 12)
                
                # Apply trojan modifications to expected values
                if trojan_trigger1:
                    expected_res = expected_res ^ 0x01
                    expected_cout = ~expected_cout & 0x01
                elif trojan_trigger2:
                    expected_res = expected_res & 0x05
                    expected_cout = ~expected_cout & 0x01
                elif trojan_trigger3:
                    expected_res = expected_res | 0x0A
                    expected_cout = ~expected_cout & 0x01
                
                # Assert the expected output values
                assert result == expected_res, \
                    f"op={op}, a={a}, b={b}: result={result}, expected={expected_res}"
                assert cout == expected_cout, \
                    f"op={op}, a={a}, b={b}: cout={cout}, expected={expected_cout}"
                
                dut._log.debug(f"op={op}, a={a:04b}, b={b:04b} -> res={result:04b}, cout={cout}")
    
    dut._log.info("All tests passed!")
