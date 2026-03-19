set_param general.maxThreads 4
create_project -in_memory -part xc7a35tcpg236-1

read_verilog -sv [list \
    /home/brendan/synthesis_workspace/AXI4_Crossbar/rtl/axi_xbar_pkg.sv \
    /home/brendan/synthesis_workspace/AXI4_Crossbar/rtl/axi_addr_decoder.sv \
    /home/brendan/synthesis_workspace/AXI4_Crossbar/rtl/axi_arbiter.sv \
    /home/brendan/synthesis_workspace/AXI4_Crossbar/rtl/axi_err_slave.sv \
    /home/brendan/synthesis_workspace/AXI4_Crossbar/rtl/axi_r_path.sv \
    /home/brendan/synthesis_workspace/AXI4_Crossbar/rtl/axi_w_path.sv \
    /home/brendan/synthesis_workspace/AXI4_Crossbar/rtl/axi_xbar_top.sv \
]

set xdc_file "/home/brendan/synthesis_workspace/AXI4_Crossbar/synthesis_logs/clock.xdc"
set fp [open $xdc_file w]
puts $fp "create_clock -period 10.000 -name clk \[get_ports clk\]"
close $fp
read_xdc $xdc_file

synth_design -top axi_xbar_top -part xc7a35tcpg236-1

report_utilization -file /home/brendan/synthesis_workspace/AXI4_Crossbar/synthesis_logs/utilization_axi_xbar_top.rpt
report_timing_summary -file /home/brendan/synthesis_workspace/AXI4_Crossbar/synthesis_logs/timing_axi_xbar_top.rpt
