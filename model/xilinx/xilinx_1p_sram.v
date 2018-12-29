// Copyright (c) 2018  Lulinchen, All Rights Reserved
// AUTHOR : 	Lulinchen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

module xilinx_1p_sram #
	(
	parameter  WWORD = 32,
	parameter  WADDR =  5,
	parameter  DEPTH = 24
	)
	(
	input						clk,
	output reg		[WWORD-1:0]	q,
	input			[WADDR-1:0]	a,
	input						cen,

	input			[WWORD-1:0]	d,
	input						wen
	);

	xpm_memory_spram # (

	  // Common module parameters
	  .MEMORY_SIZE        (WWORD*DEPTH),           //positive integer
	  .MEMORY_PRIMITIVE   ("auto"),         //string; "auto", "distributed", "block" or "ultra";
	  .MEMORY_INIT_FILE   ("none"),         //string; "none" or "<filename>.mem" 
	  .MEMORY_INIT_PARAM  (""    ),         //string;
	  .USE_MEM_INIT       (1),              //integer; 0,1
	  .WAKEUP_TIME        ("disable_sleep"),//string; "disable_sleep" or "use_sleep_pin" 
	  .MESSAGE_CONTROL    (0),              //integer; 0,1

	  // Port A module parameters
	  .WRITE_DATA_WIDTH_A (WWORD),             //positive integer
	  .READ_DATA_WIDTH_A  (WWORD),             //positive integer
	  .BYTE_WRITE_WIDTH_A (WWORD),             //integer; 8, 9, or WRITE_DATA_WIDTH_A value
	  .ADDR_WIDTH_A       (WADDR),              //positive integer
	  .READ_RESET_VALUE_A ("0"),            //string
	  .ECC_MODE           ("no_ecc"),       //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
	  .AUTO_SLEEP_TIME    (0),              //Do not Change
	  .READ_LATENCY_A     (1),              //non-negative integer
	  .WRITE_MODE_A       ("read_first")    //string; "write_first", "read_first", "no_change" 

	) xpm_memory_spram_inst (

	  // Common module ports
	  .sleep          (1'b0),

	  // Port A module ports
	  .clka           (clk),
	  .rsta           (1'b0),
	  .ena            (~cen),
	  .regcea         (1'B1),
	  .wea            (~wen),
	  .addra          (a),
	  .dina           (d),
	  .injectsbiterra (1'b0),
	  .injectdbiterra (1'b0),
	  .douta          (q),
	  .sbiterra       (),
	  .dbiterra       ()

	);
	
	
endmodule

