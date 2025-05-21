TOPLEVEL = spi_top
MODULE = testbench.test_spi
VERILOG_SOURCES = src/spi_master.v src/spi_slave.v src/fifo.v src/spi_top.v


include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf sim_build results.xml testbench/__pycache__