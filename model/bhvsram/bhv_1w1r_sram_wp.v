// Copyright (c) 2018  Lulinchen, All Rights Reserved
// AUTHOR : 	Lulinchen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

module bhv_1w1r_sram_wp #
	(
	parameter  WWORD = 32,
	parameter  WADDR =  5,
	parameter  DEPTH = 24,
	parameter  WP = 8
	)
	(
	input						clka,
	output reg		[WWORD-1:0]	qa,
	input			[WADDR-1:0]	aa,
	input						cena,
	input						clkb,
	input			[WWORD-1:0]	db,
	input			[WADDR-1:0]	ab,
	input			[WWORD/WP-1:0]wenb,
	input						cenb
	);
	reg				[WWORD-1:0]	mem[0:((1<<WADDR)-1)];
	always @(posedge clka) if (!cena) qa <= #0.5 mem[aa];
	genvar i;
	generate	
		for (i=0; i<WWORD/WP; i=i+1) begin
			always @(posedge clkb) if (!cenb && !wenb[i] && ab < DEPTH) mem[ab][WP*i +:WP] <= #0.5 db[ WP*i +:WP];
		end
	endgenerate
endmodule

