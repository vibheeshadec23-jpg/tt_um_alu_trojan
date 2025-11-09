# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")
    
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    dut._log.info("Test ALU project behavior")
    
    # Test all operations and all input combinations
    op_names = ['ADD', 'SUB', 'AND', 'OR']
    
    for op in range(4):
        dut._log.info(f"Testing operation {op}: {op_names[op]}")
        
        for a in range(16):
            for b in range(16):
                # Set operation code first
                dut.uio_in.value = op
                # Set input values
                dut.ui_in.value = (b << 4) | a  # ui_in[7:4] = b, ui_in[3:0] = a
                
                # Wait for combinational logic to settle
                await Timer(1, units='ns')
                
                # Extract result and carry from output
                output_val = int(dut.uo_out.value)
                result = output_val & 0x0F  # uo_out[3:0]
                cout = (output_val >> 4) & 0x01  # uo_out[4]
                
                # Calculate expected values
                if op == 0:  # ADD
                    temp = a + b
                    expected_res = temp & 0x0F
                    expected_cout = (temp >> 4) & 0x01
                elif op == 1:  # SUB
                    temp = a - b
                    expected_res = temp & 0x0F
                    # For subtraction, carry out indicates borrow
                    expected_cout = 1 if temp < 0 else 0
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
                    expected_cout = (~expected_cout) & 0x01
                    trojan_active = "T1"
                elif trojan_trigger2:
                    expected_res = expected_res & 0x05
                    expected_cout = (~expected_cout) & 0x01
                    trojan_active = "T2"
                elif trojan_trigger3:
                    expected_res = expected_res | 0x0A
                    expected_cout = (~expected_cout) & 0x01
                    trojan_active = "T3"
                else:
                    trojan_active = ""
                
                # Assert the expected output values
                assert result == expected_res, \
                    f"RESULT MISMATCH: op={op_names[op]}, a={a}, b={b}: " \
                    f"result={result:04b} ({result}), expected={expected_res:04b} ({expected_res}) {trojan_active}"
                assert cout == expected_cout, \
                    f"CARRY MISMATCH: op={op_names[op]}, a={a}, b={b}: " \
                    f"cout={cout}, expected={expected_cout} {trojan_active}"
                
                # Log trojan activations
                if trojan_active:
                    dut._log.info(
                        f"TROJAN {trojan_active}: op={op_names[op]}, a={a:04b}, b={b:04b} -> "
                        f"res={result:04b}, cout={cout}"
                    )
    
    dut._log.info("All tests passed!")


@cocotb.test()
async def test_specific_cases(dut):
    """Test specific interesting cases"""
    dut._log.info("Starting specific case tests")
    
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    test_cases = [
        # (a, b, op, name)
        (5, 3, 0, "Normal ADD: 5 + 3"),
        (15, 15, 0, "Trojan 1 ADD: 15 + 15"),
        (9, 6, 0, "Trojan 2 ADD: 9 + 6"),
        (3, 12, 3, "Trojan 3 OR: 3 | 12"),
        (7, 4, 1, "Normal SUB: 7 - 4"),
        (12, 10, 2, "Normal AND: 12 & 10"),
        (0, 0, 0, "Zero ADD: 0 + 0"),
        (15, 0, 0, "Max ADD Zero: 15 + 0"),
    ]
    
    for a, b, op, name in test_cases:
        dut._log.info(f"Testing: {name}")
        dut.uio_in.value = op
        dut.ui_in.value = (b << 4) | a
        await Timer(1, units='ns')
        
        output_val = int(dut.uo_out.value)
        result = output_val & 0x0F
        cout = (output_val >> 4) & 0x01
        
        dut._log.info(f"  Result: {result:04b} ({result}), Carry: {cout}")
    
    dut._log.info("Specific case tests passed!")


@cocotb.test()
async def test_io_configuration(dut):
    """Test that IO configuration is correct"""
    dut._log.info("Testing IO configuration")
    
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    
    dut.ena.value = 1
    dut.rst_n.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    
    await ClockCycles(dut.clk, 2)
    
    # Check that uio_out and uio_oe are 0 (all bidirectional pins as inputs)
    assert int(dut.uio_out.value) == 0, "uio_out should be 0"
    assert int(dut.uio_oe.value) == 0, "uio_oe should be 0"
    
    dut._log.info("IO configuration test passed!")
