// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "global.v"

`define DRAW_2PIXEL_WIDE

module draw_rectangle(
	input					clk,
	input					rstn,
	input		[`W_PW:0]	pic_width,
	input		[`W_PH:0]	pic_height,
	input		[`W_PW:0]	x,
	input		[`W_PH:0]	y,
	input		[`W_PW:0]	w, 
	input		[`W_PH:0]	h, 
	input					vsync,
	input					hsync,
	input					de,
	output	reg				vsync_o,
	output	reg				hsync_o,
	output	reg				de_o,
	output	reg				q
	);
	
	reg	[`W_PW+1:0] 	x1;
	reg	[`W_PH+1:0] 	y1;
	reg    [7:0][`W_PW:0]    x_d;
	always @(*)    x_d[0] = x;
	always @(`CLK_RST_EDGE)
		if (`RST)    x_d[7:1] <= 0;
		else         x_d[7:1] <= x_d;
	reg    [7:0][`W_PH:0]    y_d;
	always @(*)    y_d[0] = y;
	always @(`CLK_RST_EDGE)
		if (`RST)    y_d[7:1] <= 0;
		else         y_d[7:1] <= y_d;
	reg	[7:0][`W_PW+1:0]	x1_d;
	always @(*)	x1_d[0] = x1;
	always @(`CLK_RST_EDGE)
		if (`RST)	x1_d[7:1] <= 0;
		else 		x1_d[7:1] <= x1_d;
	reg	[7:0][`W_PH+1:0]	y1_d;
	always @(*)	y1_d[0] = y1;
	always @(`CLK_RST_EDGE)
		if (`RST)	y1_d[7:1] <= 0;
		else 		y1_d[7:1] <= y1_d;
	
	always @(`CLK_RST_EDGE)
		if (`ZST)	{x1, y1} <= 0;
		else begin
			x1 <= x + w;
			y1 <= y + h;		
		end
	
	reg	[`W_PW+`W_PH+1:0]	pt0, pt1, pt2, pt3 ;
	always @(`CLK_RST_EDGE)
		if (`RST)	pt0 <= 0;
		else 		pt0 <= {y_d[2],x_d[2]};
	always @(`CLK_RST_EDGE)
		if (`RST)	pt1 <= 0;
		else 		pt1 <= {y_d[2],x1_d[1][`W_PW:0] };
	always @(`CLK_RST_EDGE)
		if (`RST)	pt2 <= 0;
		else 		pt2 <= {y1_d[1],x_d[2]};
	always @(`CLK_RST_EDGE)
		if (`RST)	pt3 <= 0;
		else 		pt3 <= {y1_d[1],x1_d[1][`W_PW:0]};
	

	reg    [7:0]    vsync_d;
	always @(*)    vsync_d[0] = vsync;
	always @(`CLK_RST_EDGE)
		if (`RST)    vsync_d[7:1] <= 0;
		else         vsync_d[7:1] <= vsync_d;
		
	wire	vsync_falling = !vsync & vsync_d[1];
	reg    [7:0]    hsync_d;
	always @(*)    hsync_d[0] = hsync;
	always @(`CLK_RST_EDGE)
		if (`RST)    hsync_d[7:1] <= 0;
		else         hsync_d[7:1] <= hsync_d;
	reg    [7:0]    de_d;
	always @(*)    de_d[0] = de;
	always @(`CLK_RST_EDGE)
		if (`RST)    de_d[7:1] <= 0;
		else         de_d[7:1] <= de_d;
	
	reg			[`W_PW:0]	 cnt_h;
	reg			[`W_PH:0]	 cnt_v;
	wire 		de_falling = !de & de_d[1];
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_h <= 0;
		else 		cnt_h <= de? cnt_h + 1 : 0;
	always @(`CLK_RST_EDGE)
		if (`RST)					cnt_v <= 0;
		else if (vsync_falling)		cnt_v <= 0;
		else if (de_falling)		cnt_v <= cnt_v + 1;
	
	reg    [7:0][`W_PW:0]    cnt_h_d;
	always @(*)    cnt_h_d[0] = cnt_h;
	always @(`CLK_RST_EDGE)
		if (`RST)    cnt_h_d[7:1] <= 0;
		else         cnt_h_d[7:1] <= cnt_h_d;
	reg    [7:0][`W_PH:0]    cnt_v_d;
	always @(*)    cnt_v_d[0] = cnt_v;
	always @(`CLK_RST_EDGE)
		if (`RST)    cnt_v_d[7:1] <= 0;
		else         cnt_v_d[7:1] <= cnt_v_d;
	
	wire	[`W_PW+`W_PH+1:0]		cur_pt = {cnt_v, cnt_h};

	reg		[7:0]	horline_cnt;
	
	reg		cur_eq_pt0, cur_eq_pt1, cur_eq_pt2,cur_eq_pt3;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	{cur_eq_pt0, cur_eq_pt1, cur_eq_pt2,cur_eq_pt3} <= 0;
		else begin
			cur_eq_pt0 <=  pt0 == cur_pt; 
			cur_eq_pt1 <=  pt1 == cur_pt; 		
			cur_eq_pt2 <=  pt2 == cur_pt; 		
			cur_eq_pt3 <=  pt3 == cur_pt; 		
		end
	
	
	reg    			hor_start_pt, hor_end_pt, ver_start_pt, ver_end_pt;
	reg  [7:0]  	hor_start_pt_cnt, hor_end_pt_cnt, ver_start_pt_cnt, ver_end_pt_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)    {hor_start_pt, hor_end_pt, ver_start_pt, ver_end_pt} <= 0;
		else  begin
			hor_start_pt <=  cur_eq_pt0 || cur_eq_pt2; 
			hor_end_pt   <=  cur_eq_pt1 || cur_eq_pt3; 
			ver_start_pt <=  cur_eq_pt0 || cur_eq_pt1; 		
			ver_end_pt   <=  cur_eq_pt2 || cur_eq_pt3;  	
		end
		
	assign 	pt_cnt0 = cur_eq_pt0? 1:0;
	assign 	pt_cnt1 = cur_eq_pt1? 1:0;
	assign 	pt_cnt2 = cur_eq_pt2? 1:0;
	assign 	pt_cnt3 = cur_eq_pt3? 1:0;
	
	always @(`CLK_RST_EDGE)
		if (`RST) 	{hor_start_pt_cnt, hor_end_pt_cnt, ver_start_pt_cnt, ver_end_pt_cnt} <= 0;
		else begin
			hor_start_pt_cnt 	<= pt_cnt0 + pt_cnt2;
			hor_end_pt_cnt 		<= pt_cnt1 + pt_cnt3;
			ver_start_pt_cnt 	<= pt_cnt0 + pt_cnt1;
			ver_end_pt_cnt 		<= pt_cnt2 + pt_cnt3;
		end
		
	always @(`CLK_RST_EDGE)
		if (`RST)	horline_cnt <= 0;
		else if (de_d[2])
			horline_cnt <= horline_cnt +  hor_start_pt_cnt - hor_end_pt_cnt;
			// case({hor_start_pt, hor_end_pt})
				// 2'b10: horline_cnt <= horline_cnt+1;
				// 2'b01: horline_cnt <= horline_cnt-1;
			// endcase
		else 	horline_cnt <= 0;
	
	// ver_line
	reg		[10:0]	aa_line_buf;
	//reg				cena_line_buf;
	wire				cena_line_buf;
	reg		[10:0]	ab_line_buf;
	reg		[7:0]	db_line_buf;
	reg				cenb_line_buf;
	wire	[7:0]	qa_line_buf;
	
	rfdp2048x8 line_buf(
		.CLKA   (clk),
		.CENA   (cena_line_buf),
		.AA     (aa_line_buf),
		.QA     (qa_line_buf),
		.CLKB   (clk),
		.CENB   (cenb_line_buf),
		.AB     (ab_line_buf),
		.DB     (db_line_buf)
		);
	
	//always @(*) cena_line_buf = 1'b0;
	assign cena_line_buf = 1'b0;
	always @(*) aa_line_buf = cnt_h;
	
	reg	[7:0][10:0]	qa_line_buf_d;
	always @(*)	qa_line_buf_d[0] = qa_line_buf;
	always @(`CLK_RST_EDGE)
		if (`RST)	qa_line_buf_d[7:1] <= 0;
		else 		qa_line_buf_d[7:1] <= qa_line_buf_d;
		
	
	reg    [7:0]    cur_ver_cnt;
	reg    [7:0]    next_ver_cnt;
	
	
	always @(`CLK_RST_EDGE)
		if (`RST)   		 	cur_ver_cnt <= 0;
		// else if(cnt_v_d[1]==0)  cur_ver_cnt <= ver_start_pt;
		// else 				 	cur_ver_cnt <= qa_line_buf + ver_start_pt;
		else if(cnt_v_d[2]==0)  cur_ver_cnt <= ver_start_pt_cnt;
		else 				 	cur_ver_cnt <= qa_line_buf_d[1] + ver_start_pt_cnt;
	
	// draw one one pixel for the left below  point
	always @(`CLK_RST_EDGE)
		if (`RST)   		 	next_ver_cnt <= 0;
		// else if(cnt_v_d[1]==0)  next_ver_cnt <= ver_start_pt - ver_end_pt;
		// else 				 	next_ver_cnt <= qa_line_buf + ver_start_pt - ver_end_pt;
		else if(cnt_v_d[2]==0)  next_ver_cnt <= ver_start_pt_cnt - ver_end_pt_cnt;
		else 				 	next_ver_cnt <= qa_line_buf_d[1] + ver_start_pt_cnt - ver_end_pt_cnt;
	
	always @(`CLK_RST_EDGE)
		if (`RST)    db_line_buf <= 0;
	//	else         db_line_buf <= cur_ver_cnt;
		else         db_line_buf <= next_ver_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)    cenb_line_buf <= 1;
		else         cenb_line_buf <= ~de_d[3];
	always @(`CLK_RST_EDGE)
		if (`RST)    ab_line_buf <= 0;
		else         ab_line_buf <= cnt_h_d[3];
		
`ifdef DRAW_2PIXEL_WIDE


	// ver_line
	reg		[10:0]	aa_horline_buf;
	//reg				cena_horline_buf;
	wire				cena_horline_buf;
	reg		[10:0]	ab_horline_buf;
	reg		[7:0]	db_horline_buf;
	reg				cenb_horline_buf;
	wire	[7:0]	qa_horline_buf;
	
	rfdp2048x8 horline_buf(
		.CLKA   (clk),
		.CENA   (cena_horline_buf),
		.AA     (aa_horline_buf),
		.QA     (qa_horline_buf),
		.CLKB   (clk),
		.CENB   (cenb_horline_buf),
		.AB     (ab_horline_buf),
		.DB     (db_horline_buf)
		);
		
	always @(`CLK_RST_EDGE)
		if (`RST)    db_horline_buf <= 0;
		else         db_horline_buf <= horline_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)    cenb_horline_buf <= 1;
		else         cenb_horline_buf <= ~de_d[3];
	always @(`CLK_RST_EDGE)
		if (`RST)    ab_horline_buf <= 0;
		else         ab_horline_buf <= cnt_h_d[3];
	assign cena_horline_buf = 1'b0;
	always @(*) aa_horline_buf = cnt_h;
	
	reg		[7:0]		qa_horline_buf_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	qa_horline_buf_d1 <= 0;
		else 		qa_horline_buf_d1 <= qa_horline_buf;
		
	reg			horline_expand;
	always @(`CLK_RST_EDGE)
		if (`ZST)					horline_expand <= 0;
		else if (cnt_v_d[2]==0) 	horline_expand <= 0;
		else 						horline_expand <= |qa_horline_buf_d1;
	reg			horline_expand_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	horline_expand_d1 <= 0;
		else 		horline_expand_d1 <= horline_expand;

	reg		q_sp;
	reg		q_sp_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	q_sp_d1 <= 0;
		else 		q_sp_d1 <= q_sp;
		
	//always@*	q = q_sp || q_sp_d1 || horline_expand_d1;
	always@*	q = q_sp || q_sp_d1;
	always @(`CLK_RST_EDGE)
		if (`RST)	q_sp <= 0;
	//	else 		q <= horline_cnt != 0;
		else 		q_sp <= horline_cnt != 0 || cur_ver_cnt !=0 || horline_expand || horline_expand_d1;
`else
	always @(`CLK_RST_EDGE)
		if (`RST)	q <= 0;
	//	else 		q <= horline_cnt != 0;
		else 		q <= horline_cnt != 0 || cur_ver_cnt !=0;
`endif

	always @(`CLK_RST_EDGE)
		if (`RST)	de_o <= 0;
		else 		de_o <= de_d[3];
	always @(`CLK_RST_EDGE)
		if (`RST)	hsync_o <= 0;
		else 		hsync_o <= hsync_d[3];
	always @(`CLK_RST_EDGE)
		if (`RST)	vsync_o <= 0;
		else 		vsync_o <= vsync_d[3];
	
endmodule
