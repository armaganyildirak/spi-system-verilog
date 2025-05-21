import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
import random
import logging

SPI_MODES = [(0, 0), (0, 1), (1, 0), (1, 1)]
DATA_WIDTH = 8

@cocotb.test()
async def spi_master_slave_loopback(dut):
    """Test SPI master <-> slave full-duplex loopback in all 4 modes"""
    dut._log.setLevel(logging.INFO)

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())  # 100 MHz

    # Reset
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0

    # Set common config
    dut.clk_div.value = 2
    dut.lsb_first.value = 0  # MSB first

    for cpol, cpha in SPI_MODES:
        dut._log.info(f"==== Testing SPI Mode CPOL={cpol}, CPHA={cpha} ====")
        dut.cpol.value = cpol
        dut.cpha.value = cpha

        for i in range(5):  # 5 transactions per mode
            tx_data = random.randint(0, 2**DATA_WIDTH - 1)
            dut._log.info(f"Test #{i+1}: Transmitting 0x{tx_data:02X}")

            # Enqueue TX data
            dut.wr_data.value = tx_data
            dut.wr_en.value = 1
            await RisingEdge(dut.clk)
            dut.wr_en.value = 0

            # Preload slave with same value (echo)
            dut.tx_data.value = tx_data

            # Wait for transfer complete
            timeout = 0
            while dut.int_done.value == 0:
                await RisingEdge(dut.clk)
                timeout += 1
                assert timeout < 5000, "Timeout waiting for int_done"

            await RisingEdge(dut.clk)

            # Read received data
            dut.rd_en.value = 1
            await RisingEdge(dut.clk)
            rx_data = int(dut.rd_data.value)
            dut.rd_en.value = 0

            assert rx_data == tx_data, f"Mismatch: TX=0x{tx_data:02X}, RX=0x{rx_data:02X}"
            dut._log.info(f"Success: TX=RX=0x{rx_data:02X}")

        dut._log.info(f"Mode CPOL={cpol}, CPHA={cpha} passed.\n")

    dut._log.info("All SPI modes passed loopback test.")
