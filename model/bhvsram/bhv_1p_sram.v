// Copyright (c) 2018  Lulinchen, All Rights Reserved
// AUTHOR : 	Lulinchen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

module bhv_1p_sram #
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

	reg				[WWORD-1:0]	mem[0:((1<<WADDR)-1)];
	always @(posedge clk) if (!cen) q <= #0.5 mem[a];
	always @(posedge clk) if (!wen && a < DEPTH) mem[a] <= #0.5 d;
endmodule

