// Copyright (c) 2018  Lulinchen, All Rights Reserved
// AUTHOR : 	Lulinchen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

module xilinx_1w1r_sram #
	(
	parameter  WWORD = 32,
	parameter  WADDR =  5,
	parameter  DEPTH = 24
	)
	(
	input						clka,
	output reg		[WWORD-1:0]	qa,
	input			[WADDR-1:0]	aa,
	input						cena,

	input						clkb,
	input			[WWORD-1:0]	db,
	input			[WADDR-1:0]	ab,
	input						cenb
	);

	
	xpm_memory_sdpram # (
	  // Common module parameters
	  .MEMORY_SIZE        (WWORD*DEPTH),            //positive integer
	  .MEMORY_PRIMITIVE   ("auto"),          //string; "auto", "distributed", "block" or "ultra";
	  .CLOCKING_MODE      ("independent_clock"),  //string; "common_clock", "independent_clock" 
	  .MEMORY_INIT_FILE   ("none"),          //string; "none" or "<filename>.mem" 
	  .MEMORY_INIT_PARAM  (""    ),          //string;
	  .USE_MEM_INIT       (1),               //integer; 0,1
	  .WAKEUP_TIME        ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin" 
	  .MESSAGE_CONTROL    (0),               //integer; 0,1
	  .ECC_MODE           ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
	  .AUTO_SLEEP_TIME    (0),               //Do not Change

	  // Port A module parameters
	  .WRITE_DATA_WIDTH_A (WWORD),              //positive integer
	  .BYTE_WRITE_WIDTH_A (WWORD),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
	  .ADDR_WIDTH_A       (WADDR),               //positive integer

	  // Port B module parameters
	  .READ_DATA_WIDTH_B  (WWORD),              //positive integer
	  .ADDR_WIDTH_B       (WADDR),               //positive integer
	  .READ_RESET_VALUE_B ("0"),             //string
	  .READ_LATENCY_B     (1),               //non-negative integer
	  .WRITE_MODE_B       ("no_change")     //string; "write_first", "read_first", "no_change" 

	) xpm_memory_sdpram_inst (

	  // Common module ports
	  .sleep          (1'b0),

	  // Port A module ports
	  .clka           (clkb),
	  .ena            (~cenb),
	  .wea            (1'b1),
	  .addra          (ab),
	  .dina           (db),
	  .injectsbiterra (1'b0),
	  .injectdbiterra (1'b0),

	  // Port B module ports
	  .clkb           (clka),
	  .rstb           (1'b0),
	  .enb            (~cena),
	  .regceb         (1'b1),
	  .addrb          (aa),
	  .doutb          (qa),
	  .sbiterrb       (),
	  .dbiterrb       ()
	);
	
	
endmodule

