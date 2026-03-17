# Brendan Lynskey 2025
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../../rtl/axi_xbar_pkg.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_addr_decoder.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_arbiter.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_err_slave.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_w_path.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_r_path.sv
VERILOG_SOURCES += $(PWD)/../../../rtl/axi_xbar_top.sv
VERILOG_SOURCES += $(PWD)/../../../tb/sv/axi_slave_bfm.sv
VERILOG_SOURCES += $(PWD)/tb_wrapper.sv

TOPLEVEL = tb_xbar_wrapper
MODULE   = test_axi_xbar_top

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim
