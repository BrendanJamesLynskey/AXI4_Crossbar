# Brendan Lynskey 2025
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../../rtl/axi_xbar_pkg.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_arbiter.sv

TOPLEVEL = axi_arbiter
MODULE   = test_axi_arbiter

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim
