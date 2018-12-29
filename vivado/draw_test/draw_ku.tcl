

set outputDir ./tcl_output
file mkdir $outputDir
set_part xcku060-ffva1156-2-e
#set_part xcku040-ffva1156-2-e

set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]

set top_design system_top
# STEP#1: setup design sources and constraints
set INCLUDES { ../../common/src  ../src  ../../src}

set GENERATE_NETLIST 	"0"
set GENERATE_EDN	 	"0"
set WITH_DEBUG_CORE	 	"0"



set CAM_CLK_PORT 			{vi_clk} 
set CLK_PORT 				{p0_c1}
set CLK_REF_PORT 			{clk_ref}
set DDR_UI_CLK				{xddrc_ui_clk}


set CLK_REF_PERIOD			3.33
set CLK_PERIOD				5          
set CAM_CLK_PERIOD	 		6.73
# set CAM_CLK_PERIOD	 		3.33
set DDR_UI_CLK_PERIOD		3.33

set DEFINES	" FPGA_0_XILINX"



read_verilog -sv ../../src/top/draw_top.v
read_verilog -sv ../../src/osd.v
read_verilog -sv ../../src/draw_rectangle.v


read_verilog -sv ../../model/xilinx/xilinx_1p_sram.v
read_verilog -sv ../../model/xilinx/xilinx_1w1r_sram.v
read_verilog -sv ../../model/xilinx/xilinx_1w1r_sram_wp8.v
read_verilog -sv ../../model/xilinx/xilinx_srams.v


read_ip  ../../model/xilinx/ku/pll/pll_main_250/pll_main.xci

read_xdc 	./ku_HPC_TB_FMCH_HDMI2.xdc


set fp [open $outputDir/syndefines.v w]
puts $fp "$DEFINES"
close $fp

if { $GENERATE_NETLIST==1 } {
	synth_design -top $top_design  -verilog_define $DEFINES  -include_dirs $INCLUDES -flatten_hierarchy none 
	write_verilog -cell face -mode funcsim -force $outputDir/post_synth_netlist.v
#	write_verilog -cell vj -mode funcsim -force $outputDir/vj.v
	quit
} else {
	synth_design -top $top_design  -verilog_define $DEFINES  -include_dirs $INCLUDES -flatten_hierarchy rebuilt
}


#create_clock -period $CLK_PERIOD           	-name $CLK_PORT              	[get_nets $CLK_PORT]
create_clock -period $CAM_CLK_PERIOD 		-name $CAM_CLK_PORT          	[get_nets $CAM_CLK_PORT]
create_clock -period $CLK_REF_PERIOD       	-name $CLK_REF_PORT             [get_nets $CLK_REF_PORT]


set_clock_groups \
		-group [get_clocks -include_generated_clocks $CLK_REF_PORT] \
		-group [get_clocks -include_generated_clocks $CAM_CLK_PORT] \
	-asynchronous

	# -group [get_clocks -include_generated_clocks $VO_CLK_PORT] \


set_false_path -through [get_ports rst_i]
set_false_path -through [get_nets rstn]

write_checkpoint -force $outputDir/post_synth
report_utilization -file $outputDir/post_synth_util.rpt


if { $GENERATE_EDN==1 } {
	write_edif -force -cell [get_cells dwem/u] ./edn/
	#write_verilog  -cell [get_cells dwem/u] -mode port d880.vm
	write_verilog  -force -cell [get_cells dwem/u] -mode synth_stub ./edn/d880.vm
	if { $WITH_TS_DEMUX==1 } {
		write_edif -force -cell [get_cells tsdemux] ./edn/
	#	write_verilog -cell [get_cells tsdemux] -mode port jw_ts_demux.vm
		write_verilog -force -cell [get_cells tsdemux] -mode synth_stub ./edn/jw_ts_demux.vm
	}	
} else {
	opt_design
	place_design
	phys_opt_design
	#power_opt_design
	#write_checkpoint -force $outputDir/post_place
	#report_timing_summary -file $outputDir/post_place_timing_summary.rpt
	#report_timing -max_paths 1000 -path_type summary -slack_lesser_than 0 -file $outputDir/post_route_setup_timing_violations.rpt

	# STEP#4: run router, report actual utilization and timing, write checkpoint design, run drc, write verilog and xdc out
	#
	route_design
	#write_checkpoint -force $outputDir/post_route
	report_timing_summary -file $outputDir/post_route_timing_summary.rpt
	report_timing -max_paths 10000 -path_type summary -slack_lesser_than 0 -file $outputDir/post_route_setup_timing_violations.rpt
	report_clock_utilization -file $outputDir/clock_util.rpt
	report_utilization -file $outputDir/post_route_util.rpt
	#report_power -file $outputDir/post_route_power.rpt
	#report_drc -file $outputDir/post_imp_drc.rpt
	#write_verilog -force $outputDir/ddrtest_impl_netlist.v
	#write_xdc -no_fixed_only -force $outputDir/ddrtest_impl.xdc
	#
	# STEP#5: generate a bitstream
	# 
	
	set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
	set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
	set_property CONFIG_VOLTAGE 1.8 [current_design]
	set_property CFGBVS GND [current_design]
	set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
	set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
	set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
	
	write_bitstream -force $outputDir/impl.bit
	
	if { $WITH_DEBUG_CORE==1 } {
		write_debug_probes -force $outputDir/xx.ltx 
	}

}
 
 
 
 
quit

