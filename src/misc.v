// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "global.v"
module go_CDC_go(
	input					clk_i,
	input					rstn_i,
	input					go_i,	
	input					clk_o,
	input					rst_o,
	output					go_o
	);
	reg						flip_i;
	
	always @(posedge clk_i or negedge rstn_i)
		if (!rstn_i)    flip_i <= 0;
		else if (go_i) flip_i <= ~flip_i;
	//=====================================================	
	reg						flip_o_meta;
	reg						flip_o     ;
	reg						flip_o_p1  ;
	
	assign  go_o = (flip_o_p1 != flip_o);	
	always @(posedge clk_o or negedge rst_o)
		if (!rst_o) begin
			flip_o_meta <= 0;
			flip_o <= 0;
			flip_o_p1 <= 0;
		end else begin
			flip_o_meta <= flip_i ;
			flip_o <= flip_o_meta;
			flip_o_p1 <= flip_o;
		end
	
endmodule	

