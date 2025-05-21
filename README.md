# SPI Master-Slave with Loopback Testbench

A Verilog implementation of an SPI (Serial Peripheral Interface) master and slave with full-duplex loopback testing using Cocotb.

## Features
- Supports all SPI modes (CPOL=0/1, CPHA=0/1)
- 8-bit data width (configurable)
- 16-entry FIFO buffers for TX/RX
- Configurable clock divider (default: 2)
- MSB/LSB first transmission
- Full-duplex loopback testbench

## Files
- `src/spi_top.v` - Top-level module connecting master and slave
- `src/spi_master.v` - SPI master with FIFO
- `src/spi_slave.v` - SPI slave with synchronized inputs
- `src/fifo.v` - FIFO buffer implementation
- `testbench/test_spi.py` - Cocotb test script
- `Makefile` - Build and simulation script

## Requirements
- Icarus Verilog (or other Verilog simulator)
- Python
- Cocotb

## Usage
1. Run the test:
```bash
make
```
2. Clean generated files:
```bash
make clean
```

## Test Result

The testbench tests all four SPI modes, sending 5 random 8-bit transactions per mode and verifying loopback data matches.

```
     0.00ns INFO     cocotb                             Running on Icarus Verilog version 12.0 (stable)
     0.00ns INFO     cocotb                             Running tests with cocotb v1.9.2 from /usr/lib/python3.13/site-packages/cocotb
     0.00ns INFO     cocotb                             Seeding Python random module with 1747852272
     0.00ns INFO     cocotb.regression                  Found test testbench.test_spi.spi_master_slave_loopback
     0.00ns INFO     cocotb.regression                  running spi_master_slave_loopback (1/1)
                                                          Test SPI master <-> slave full-duplex loopback in all 4 modes
     0.00ns INFO     cocotb.spi_top                     ==== Testing SPI Mode CPOL=0, CPHA=0 ====
     0.00ns INFO     cocotb.spi_top                     Test #1: Transmitting 0x39
   400.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x39
   400.00ns INFO     cocotb.spi_top                     Test #2: Transmitting 0x75
   800.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x75
   800.00ns INFO     cocotb.spi_top                     Test #3: Transmitting 0xA1
  1200.00ns INFO     cocotb.spi_top                     Success: TX=RX=0xA1
  1200.00ns INFO     cocotb.spi_top                     Test #4: Transmitting 0x94
  1600.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x94
  1600.00ns INFO     cocotb.spi_top                     Test #5: Transmitting 0x35
  2000.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x35
  2000.00ns INFO     cocotb.spi_top                     Mode CPOL=0, CPHA=0 passed.

  2000.00ns INFO     cocotb.spi_top                     ==== Testing SPI Mode CPOL=0, CPHA=1 ====
  2000.00ns INFO     cocotb.spi_top                     Test #1: Transmitting 0xA4
  2420.00ns INFO     cocotb.spi_top                     Success: TX=RX=0xA4
  2420.00ns INFO     cocotb.spi_top                     Test #2: Transmitting 0x8F
  2840.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x8F
  2840.00ns INFO     cocotb.spi_top                     Test #3: Transmitting 0xDB
  3260.00ns INFO     cocotb.spi_top                     Success: TX=RX=0xDB
  3260.00ns INFO     cocotb.spi_top                     Test #4: Transmitting 0xB2
  3680.00ns INFO     cocotb.spi_top                     Success: TX=RX=0xB2
  3680.00ns INFO     cocotb.spi_top                     Test #5: Transmitting 0xD0
  4100.00ns INFO     cocotb.spi_top                     Success: TX=RX=0xD0
  4100.00ns INFO     cocotb.spi_top                     Mode CPOL=0, CPHA=1 passed.

  4100.00ns INFO     cocotb.spi_top                     ==== Testing SPI Mode CPOL=1, CPHA=0 ====
  4100.00ns INFO     cocotb.spi_top                     Test #1: Transmitting 0x82
  4500.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x82
  4500.00ns INFO     cocotb.spi_top                     Test #2: Transmitting 0xC2
  4900.00ns INFO     cocotb.spi_top                     Success: TX=RX=0xC2
  4900.00ns INFO     cocotb.spi_top                     Test #3: Transmitting 0x0F
  5300.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x0F
  5300.00ns INFO     cocotb.spi_top                     Test #4: Transmitting 0x9B
  5700.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x9B
  5700.00ns INFO     cocotb.spi_top                     Test #5: Transmitting 0x9D
  6100.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x9D
  6100.00ns INFO     cocotb.spi_top                     Mode CPOL=1, CPHA=0 passed.

  6100.00ns INFO     cocotb.spi_top                     ==== Testing SPI Mode CPOL=1, CPHA=1 ====
  6100.00ns INFO     cocotb.spi_top                     Test #1: Transmitting 0xE9
  6520.00ns INFO     cocotb.spi_top                     Success: TX=RX=0xE9
  6520.00ns INFO     cocotb.spi_top                     Test #2: Transmitting 0x99
  6940.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x99
  6940.00ns INFO     cocotb.spi_top                     Test #3: Transmitting 0x07
  7360.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x07
  7360.00ns INFO     cocotb.spi_top                     Test #4: Transmitting 0xE7
  7780.00ns INFO     cocotb.spi_top                     Success: TX=RX=0xE7
  7780.00ns INFO     cocotb.spi_top                     Test #5: Transmitting 0x24
  8200.00ns INFO     cocotb.spi_top                     Success: TX=RX=0x24
  8200.00ns INFO     cocotb.spi_top                     Mode CPOL=1, CPHA=1 passed.

  8200.00ns INFO     cocotb.spi_top                     All SPI modes passed loopback test.
  8200.00ns INFO     cocotb.regression                  spi_master_slave_loopback passed
  8200.00ns INFO     cocotb.regression                  ******************************************************************************************************
                                                        ** TEST                                          STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                        ******************************************************************************************************
                                                        ** testbench.test_spi.spi_master_slave_loopback   PASS        8200.00           0.07     114913.22  **
                                                        ******************************************************************************************************
                                                        ** TESTS=1 PASS=1 FAIL=0 SKIP=0                               8200.00           0.31      26268.68  **
                                                        ******************************************************************************************************
```