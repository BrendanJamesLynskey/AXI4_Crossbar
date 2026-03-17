# Brendan Lynskey 2025
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../../rtl/axi_xbar_pkg.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_err_slave.sv

TOPLEVEL = axi_err_slave
MODULE   = test_axi_err_slave

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim
