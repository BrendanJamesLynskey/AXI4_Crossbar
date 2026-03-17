# Brendan Lynskey 2025
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../../rtl/axi_xbar_pkg.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_addr_decoder.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_arbiter.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_w_path.sv

TOPLEVEL = axi_w_path
MODULE   = test_axi_w_path

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim
