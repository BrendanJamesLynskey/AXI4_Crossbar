# Brendan Lynskey 2025
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../../rtl/axi_xbar_pkg.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_addr_decoder.sv

TOPLEVEL = axi_addr_decoder
MODULE   = test_axi_addr_decoder

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim
