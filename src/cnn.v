// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION
`include "global.v"

module iterator #(
	parameter OUTPUT_BATCH = 5,   //
	parameter KERNEL_SIZEX = 5,   //
	parameter KERNEL_SIZEY = 5,   //
	parameter STEP = 1,
	parameter INPUT_WIDTH = 32,
	parameter INPUT_HEIGHT = 32
	)(
	input					clk,
	input					rstn,
	input					go,
	output reg				first_data,
	output reg				last_data,
	
	output reg				batch_go,
	
	output reg	[`W_OUPTUT_BATCH:0]		aa_bias,
	output reg	[15:0]		aa_data,
	output reg	[15:0]		aa_weight,
	output reg				cena,
	output reg				ready
	);
	
	reg		[`W_OUPTUT_BATCH :0] 	batch_cnt;
	reg		[`W_PLANEW :0] 	col;
	reg		[`W_PLANEH :0] 	row;
	reg		[`W_KERNEL :0] 	cnt_kx, cnt_ky;
	
	//go	+|
	//max_f  					 +|
	//en	 |++++++++++++++++++++|
	//cnt	 |0..............MAX-1| MAX		
	reg							cnt_kx_e;
	reg		[ `W_KERNEL :0]		cnt_kx;
	wire						cnt_kx_max_f = cnt_kx == KERNEL_SIZEX-1;
	wire						cnt_ky_max_f = cnt_ky == KERNEL_SIZEY-1;
	//TODO  // not full correct here
	wire						col_max_f = col == INPUT_WIDTH - KERNEL_SIZEX + 1 -1;   
	wire						row_max_f = row == INPUT_HEIGHT - KERNEL_SIZEY + 1 -1;
	wire						batch_cnt_max_f = batch_cnt == OUTPUT_BATCH -1;
	
	wire		end_cnt_kx_e = cnt_kx_max_f & cnt_ky_max_f & col_max_f & row_max_f & batch_cnt_max_f;
	always @(`CLK_RST_EDGE)
		if (`RST)				cnt_kx_e <= 0;
		else if (go)			cnt_kx_e <= 1;
		else if (end_cnt_kx_e)	cnt_kx_e <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)			cnt_kx <= 0;
		else if(cnt_kx_e)	cnt_kx <= cnt_kx_max_f? 0: cnt_kx + 1;
		else				cnt_kx <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)				cnt_ky <= 0;
		else if (cnt_kx_e) begin
			if (cnt_kx_max_f)	cnt_ky <= cnt_ky_max_f?  0 : cnt_ky+1;
		end else 				cnt_ky <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)					col <= 0;
		else if (cnt_kx_e) begin	
			if (cnt_kx_max_f & cnt_ky_max_f)	col <= col_max_f? 0 : col + STEP;
		end else					col <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)					row <= 0;
		else if (cnt_kx_e) begin	
			if (cnt_kx_max_f & cnt_ky_max_f & col_max_f)	row <= row_max_f? 0 : row + STEP;
		end else					row <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)					batch_cnt <= 0;
		else if (cnt_kx_e) begin	
			if (cnt_kx_max_f & cnt_ky_max_f & col_max_f & row_max_f)	batch_cnt <= batch_cnt_max_f? 0 : batch_cnt + 1;
		end else					batch_cnt <= 0;
		
		
		
		
	always @(`CLK_RST_EDGE)
		if (`RST)	aa_data <= 0;
		else 		aa_data <= row * INPUT_WIDTH + col + cnt_ky * INPUT_WIDTH + cnt_kx;
	always @(`CLK_RST_EDGE)
		if (`RST)	aa_weight <= 0;
		else 		aa_weight <= batch_cnt*KERNEL_SIZEX*KERNEL_SIZEY + cnt_ky * KERNEL_SIZEX + cnt_kx;
	always @(`CLK_RST_EDGE)
		if (`RST)	aa_bias <= 0;
		else 		aa_bias <= batch_cnt;
		
	always @(`CLK_RST_EDGE)
		if (`RST)	cena <= 1;
		else 		cena <= ~cnt_kx_e;
	always @(`CLK_RST_EDGE)
		if (`RST)	first_data <= 1;
		else 		first_data <= cnt_kx_e && cnt_ky==0 && cnt_kx==0;
	always @(`CLK_RST_EDGE)
		if (`RST)	last_data <= 1;
		else 		last_data <= cnt_kx_e && cnt_kx_max_f && cnt_ky_max_f;
	always @(`CLK_RST_EDGE)
		if (`RST)	batch_go <= 1;
		else 		batch_go <= cnt_kx_e && cnt_ky==0 && cnt_kx==0 && row ==0 && col==0;

	always @(`CLK_RST_EDGE)
		if (`RST)	ready <= 0;
		else 		ready <= end_cnt_kx_e;
endmodule



module max_pool #(
	parameter INPUT_NUM = 6   // input plane_num
	)(
	input												clk,
	input												rstn,
	input												go,
	input												en,
	input												first_data,
	input												last_data,
	input		[`WDP*INPUT_NUM-1:0]					data_i,
	output reg											q_en,
	output reg	[`WDP*INPUT_NUM-1:0]					q
	);
	
	
	reg		[0:0]		en_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	en_d1 <= 0;
		else 		en_d1 <= en;
	reg		[0:0]		first_data_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	first_data_d1 <= 0;
		else 		first_data_d1 <= first_data;	
	reg		[0:0]		last_data_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	last_data_d1 <= 0;
		else 		last_data_d1 <= last_data;
	
	//wire	[0:INPUT_NUM-1][`WD:0]	d_in = data_i;
	reg		[0:INPUT_NUM-1][`WD:0]	d_in;
	reg		[0:INPUT_NUM-1][`WD:0]	max_temp;
	always @(`CLK_RST_EDGE)
		if (`ZST)	d_in <= 0;
		else 		d_in <= data_i;
	genvar i;
	generate 
		for (i=0; i<INPUT_NUM; i=i+1) begin : out_num
			always @(`CLK_RST_EDGE)
				if (`RST)							max_temp[i] <= 0;
				else if (first_data_d1)			max_temp[i] <= d_in[i];
				else if ($signed(d_in[i]) > $signed(max_temp[i]))	max_temp[i] <= d_in[i];
		end
	endgenerate
	
	always @(`CLK_RST_EDGE)
		if (`RST)	q_en <= 0;
	//	else 		q_en <= en & last_data;
		else 		q_en <= en_d1 & last_data_d1;
	assign q = max_temp;

endmodule


module relu #(
	parameter INPUT_NUM = 6   // input plane_num
	)(
	input												clk,
	input												rstn,
	input												go,
	input												en,
	input												first_data,
	input												last_data,
	input		[`WDP*INPUT_NUM-1:0]					data_i,
	output reg											q_en,
	output reg	[`WDP*INPUT_NUM-1:0]					q
	);
	

	wire	[0:INPUT_NUM-1][`WD:0]	d_in = data_i;
	reg		[0:INPUT_NUM-1][`WD:0]	max_temp;
	
	genvar i;
	generate 
		for (i=0; i<INPUT_NUM; i=i+1) begin : out_num
			always @(`CLK_RST_EDGE)
				if (`RST)						max_temp[i] <= 0;
				else if (d_in[i][`WD])			max_temp[i] <= 0;
				else							max_temp[i] <= d_in[i];
		end
	endgenerate
	
	always @(`CLK_RST_EDGE)
		if (`RST)	q_en <= 0;
		else 		q_en <= en;
	assign q = max_temp;
endmodule


module conv #(
	parameter INPUT_NUM = 1,   // input plane_num
	parameter OUTPUT_NUM = 6,   
	parameter WIGHT_SHIFT = 8  
	)(
	input												clk,
	input												rstn,
	input												go,
	input												en,
	input												first_data,
	input												last_data,
	input		[`WDP*INPUT_NUM-1:0]					data_i,
	input		[`WDP_BIAS*OUTPUT_NUM-1:0]				bias,
	input		[`WDP*INPUT_NUM*OUTPUT_NUM-1:0]			weight,
	output reg											q_en,
	output reg	[`WDP*OUTPUT_NUM-1:0]					q
	);
	

	wire	[0:OUTPUT_NUM-1][0:INPUT_NUM-1][`WD:0] 	w_in = weight;
	wire	[0:OUTPUT_NUM-1][`WD_BIAS:0] 			bias_in = bias;
	wire	[0:OUTPUT_NUM-1]						acc_q_en;
	wire	[0:OUTPUT_NUM-1][`WD:0] 				acc_q;
	
	assign q_en = acc_q_en[0];
	assign q = acc_q;
	
	
	genvar i;
	generate 
		for (i=0; i<OUTPUT_NUM; i=i+1) begin : out_num
			acc #(
				.INPUT_NUM		(INPUT_NUM),
				.WIGHT_SHIFT	(WIGHT_SHIFT)
				)acc(
				.clk			(clk),
				.rstn			(rstn),
				.go				(go),
				.en				(en),
				.first_data	(first_data),
				.last_data		(last_data),
				.data_i			(data_i),
				.bias			(bias_in[i]),
				.weight			(w_in[i]),
				.q_en			(acc_q_en[i]),
				.q              (acc_q[i])
				);
		end
	endgenerate
	 
endmodule

module acc #(
	parameter INPUT_NUM = 1,   
	parameter WIGHT_SHIFT = 8  
	)(
	input												clk,
	input												rstn,
	input												go,
	input												en,
	input												first_data,
	input												last_data,
	input		[`WDP*INPUT_NUM-1:0]					data_i,
	input		[`WD_BIAS:0]							bias,
	input		[`WDP*INPUT_NUM-1:0]					weight,
	output reg											q_en,
	output reg	[`WD:0]									q

	);


	wire	[`WDP*2-1:0]		q_mac;
	wire				q_mac_en;
	reg		[15:0]	first_data_d;
	always @(*)	first_data_d[0] = first_data;
	always @(`CLK_RST_EDGE)
		if (`RST)	first_data_d[15:1] <= 0;
		else 		first_data_d[15:1] <= first_data_d;
	reg		[15:0]	last_data_d;
	always @(*)	last_data_d[0] = last_data;
	always @(`CLK_RST_EDGE)
		if (`RST)	last_data_d[15:1] <= 0;
		else 		last_data_d[15:1] <= last_data_d;
	reg		[15:0][`WD_BIAS:0]	bias_d;
	always @(*)	bias_d[0] = bias;
	always @(`CLK_RST_EDGE)
		if (`RST)	bias_d[15:1] <= 0;
		else 		bias_d[15:1] <= bias_d;
		
	
	reg		[15:0]	q_mac_en_d;
	always @(*)	q_mac_en_d[0] = q_mac_en;
	always @(`CLK_RST_EDGE)
		if (`RST)	q_mac_en_d[15:1] <= 0;
		else 		q_mac_en_d[15:1] <= q_mac_en_d;
		
	
	reg		[`WDP*INPUT_NUM-1:0]		data_i_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	data_i_d1 <= 0;
		else 		data_i_d1 <= data_i;
	reg		[`WDP*INPUT_NUM-1:0]		weight_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	weight_d1 <= 0;
		else 		weight_d1 <= weight;
	reg		[0:0]		en_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	en_d1 <= 0;
		else 		en_d1 <= en;
		
	// delay 1+$clog2(KERNEL_SIZE_SQ)
	mac #(
		.INPUT_NUM		(INPUT_NUM)
		)mac(
		.clk			(clk),
		.rstn			(rstn),
		.d_en			(en_d1),
		.d				(data_i_d1),
		.w				(weight_d1),
		.q_en_b1		(q_mac_en_b1),
		.q_en			(q_mac_en),
		.q				(q_mac)	
		);
		
	reg	[`WDP*2-1:0]		q_mac_acc;
	always @(`CLK_RST_EDGE)
		if (`ZST)											q_mac_acc <= 0;
		else if (q_mac_en) begin
			if(first_data_d[1+$clog2(INPUT_NUM) + 1])		q_mac_acc <= $signed(q_mac) + $signed(bias_d[1+$clog2(INPUT_NUM)+1]);
			else 											q_mac_acc <= $signed(q_mac) + $signed(q_mac_acc);
		end
	
	always @(*) q = q_mac_acc[`WDP*2-1:WIGHT_SHIFT];
	
	always @(`CLK_RST_EDGE)
		if (`RST)	q_en <= 0;
		else 		q_en <= last_data_d[1+$clog2(INPUT_NUM)+1]&q_mac_en;
	
endmodule


// INPUT_NUM 4  3 clks
// INPUT_NUM 8  4 clks
// INPUT_NUM 16 5 clks
module mac#(
	parameter INPUT_NUM = 1   // input plane_num
	)(
	input									clk,
	input									rstn,
	input									d_en,
	input	[`WDP*INPUT_NUM-1:0]			d,
	input	[`WDP*INPUT_NUM-1:0]			w,
	input									q_en,
	input									q_en_b1,
	output	[`WDP*2-1:0]					q
	);
	
	parameter INPUT_NUM_PADING = 2**$clog2(INPUT_NUM);
	
	wire	[0:INPUT_NUM-1][`WD:0] 	d_in = d;
	wire	[0:INPUT_NUM-1][`WD:0] 	w_in = w;
	reg		[0:INPUT_NUM_PADING-1][`WDP*2-1:0]	mul = 0;
	
	reg		[15:0]	d_en_d;
	always @(*)	d_en_d[0] = d_en;
	always @(`CLK_RST_EDGE)
		if (`RST)	d_en_d[15:1] <= 0;
		else 		d_en_d[15:1] <= d_en_d;
		
	

	genvar i;
	genvar j;
	generate 
		for (i=0; i<INPUT_NUM; i=i+1) begin : multiply
			always @(`CLK_RST_EDGE)
				if (`RST)	mul[i] <= 0;
				else 		mul[i] <= $signed(d_in[i]) * $signed(w_in[i]);
		end
	endgenerate
	
	generate 
		if (INPUT_NUM_PADING>1) begin
			reg		[0:$clog2(INPUT_NUM_PADING)-1][0:(INPUT_NUM_PADING+1)/2 -1][`WDP*2-1:0]	sum = 0;
			for (i=0; i<$clog2(INPUT_NUM_PADING); i=i+1) begin 
				for(j=0; j < INPUT_NUM_PADING/(2**(i+1)); j++)
					if (i==0) begin
						always @(`CLK_RST_EDGE)
							if (`RST)	sum[i][j] <= 0;
							else		sum[i][j] <= $signed(mul[j*2]) + $signed(mul[j*2+1]);
					end else begin
						always @(`CLK_RST_EDGE)
							if (`RST)	sum[i][j] <= 0;
							else		sum[i][j] <= $signed(sum[i-1][j*2]) + $signed(sum[i-1][j*2+1]);
					end
			end
			assign q = sum[$clog2(INPUT_NUM_PADING)-1][0];
			assign q_en = d_en_d[$clog2(INPUT_NUM_PADING)+1];
			assign q_en_b1 = d_en_d[$clog2(INPUT_NUM_PADING)];
		end else begin
			//assign q = sum[$clog2(INPUT_NUM)-1][0][`WDP*2-1-:`WDP];
			assign q = mul[0];
			assign q_en = d_en_d[$clog2(INPUT_NUM_PADING)+1];
			assign q_en_b1 = d_en_d[$clog2(INPUT_NUM_PADING)];
		end
	endgenerate
	
endmodule


