// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "global.v"

`define	MAX_PATH			256
module tb();

	parameter  FRAME_WIDTH = 112;
	parameter  FRAME_HEIGHT = 48;
	parameter  SIM_FRAMES = 2;
	reg						rstn;
	reg						clk;
	reg						ee_clk;
	
	wire		rstn_ee = rstn;
	initial begin
		rstn = `RESET_ACTIVE;
		#(`RESET_DELAY); 
		$display("T%d rstn done#############################", $time);
		rstn = `RESET_IDLE;
	end
	
	initial begin
		clk = 1;
		forever begin
			clk = ~clk;
			#(`CLK_PERIOD_DIV2);
		end
	end
	
	initial begin
		ee_clk = 1;
		forever begin
			ee_clk = ~ee_clk;
			#(`EE_CLOCK_PERIOD_DIV2);
		end
	end
	
	reg			[15:0]			frame_width_0;
	reg			[15:0]			frame_height_0;
	reg			[31:0]			pic_to_sim;
	reg		[`MAX_PATH*8-1:0]	sequence_name_0;
		
	itf_frame_feed 		itf(clk);
	
	wire		[3:0]	digit;
	wire				ready;
	wire				go =  itf.go;
	assign 				itf.ready = ready;
	
	initial begin
		#(`RESET_DELAY)
		#(`RESET_DELAY)
		itf.drive_frame(20);
		#(100000* `TIME_COEFF)
		$finish();
	end	
	
	
	wire	[9:0]			aa_src_rom;
	wire	[`WD:0]			qa_src_rom;
	wire	[9:0]			aa_weight;
	src_rom src_rom(
		.clk			(clk),
		.rstn			(rstn),
		.aa				(aa_src_rom),
		.cena			(cena_src_rom),
		.qa				(qa_src_rom)
		);
		
	lenet lenet(
		.clk				(clk),
		.rstn				(rstn),
		.go					(go),				
		.cena_src			(cena_src_rom),
		.aa_src				(aa_src_rom),
		.qa_src				(qa_src_rom),
		.digit				(digit),		
		.ready				(ready)
		);
	
	reg		[31:0]	digit_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)			digit_cnt <= 0;
		else if (ready)	begin
			$display("T%d==process a frame %d, digit %d =============", $time, digit_cnt, digit);
			digit_cnt <= digit_cnt + 1;
		end

	
	
`ifdef DUMP_FSDB 
	initial begin
	$fsdbDumpfile("fsdb/xx.fsdb");
	$fsdbDumpvars();
	end
`endif
	
endmodule


module src_rom(
	input			clk,
	input			rstn,
	input	[9:0]	aa,
	input			cena,
	output reg		[`WD:0]	qa
	);
	logic [0:32*32-1][31:0] mem	 = {
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,   84,  185,  159,  151,   60,   36,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,  222,  254,  254,  254,  254,  241,  198,  198,  198,  198,  198,  198,  198,  198,  170,   52,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,   67,  114,   72,  114,  163,  227,  254,  225,  254,  254,  254,  250,  229,  254,  254,  140,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,   17,   66,   14,   67,   67,   67,   59,   21,  236,  254,  106,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,   83,  253,  209,   18,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,   22,  233,  256,   83,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  129,  254,  238,   44,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,   59,  249,  254,   62,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  133,  254,  187,    5,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    9,  205,  248,   58,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  126,  254,  182,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,   75,  251,  240,   57,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,   19,  221,  254,  166,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    3,  203,  254,  219,   35,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,   38,  254,  254,   77,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,   31,  224,  254,  115,    1,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  133,  254,  254,   52,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,   61,  242,  254,  254,   52,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  121,  254,  254,  219,   40,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  121,  254,  207,   18,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0, 
			   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0
			   };
		
	always @(`CLK_RST_EDGE)
		if (`RST)	qa <= 0;
		else if (!cena)		qa <= mem[aa];
endmodule



interface itf_frame_feed(input clk);
	logic			go;
	logic			ready;
	
	clocking cb@( `CLK_EDGE);
		output	go;
		input 	ready;
	endclocking	
	
	//task drive_frame(logic [`MAX_PATH*8-1:0]	sequence_name; , int nframe);
	task drive_frame(int nframe);
		integer						fd;
		integer						errno;
		reg			[640-1:0]		errinfo;
		logic [`MAX_PATH*8-1:0]	sequence_name = "./test_1000f.yuv";
		go		 <= 0;
		@cb;
		@cb;
		
		fd = $fopen(sequence_name, "rb");
		if (fd == 0) begin
			errno = $ferror(fd, errinfo);
			$display("sensor Failed to open file %0s for read.", sequence_name);
			$display("errno: %0d", errno);
			$display("reason: %0s", errinfo);
			$finish();
		end
		
		for(int f = 0; f<nframe; f++ ) begin
			@cb;
			@cb;
			for(int i = 0; i< 32*32; i++ ) begin
				$root.tb.src_rom.mem[i] <= $fgetc(fd);
			end
			@cb;
			@cb;
			go		 <= 1;
			@cb;
			go		 <= 0;
			@cb.ready;
			@cb;
			@cb;
		end
	endtask

endinterface
