// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION


`include "global.v"

module capture_lenet(
	input								clk, 
	input								rstn,
	input	[`W_PW:0]					pic_width,
	input	[`W_PH:0]					pic_height,
	input	[2:0]						cam_scale,
	input		[`W_PW:0]	x,
	input		[`W_PH:0]	y,
	input		[`W_PW:0]	w, 
	input		[`W_PH:0]	h, 
	
	input								cam_vsync_i,
	input								cam_href_i,
	input		[`W1:0]					cam_data_i,			//Y
	
	output reg							capture_ready,
	
	output reg		[`W_AFRAMEBUF:0]	ab_frame_buf,   
	output reg							cenb_frame_buf,
	output reg		[`W1:0]				db_frame_buf
	);
	
	
	reg	[7:0]	cam_vsync_i_d;
	always @(*)	cam_vsync_i_d[0] = cam_vsync_i;
	always @(`CLK_RST_EDGE)
		if (`RST)	cam_vsync_i_d[7:1] <= 0;
		else 		cam_vsync_i_d[7:1] <= cam_vsync_i_d;
	reg	[7:0]	cam_href_i_d;
	always @(*)	cam_href_i_d[0] = cam_href_i;
	always @(`CLK_RST_EDGE)
		if (`RST)	cam_href_i_d[7:1] <= 0;
		else 		cam_href_i_d[7:1] <= cam_href_i_d;
	reg	[7:0][`W1:0]	cam_data_i_d;
	always @(*)	cam_data_i_d[0] = cam_data_i;
	always @(`CLK_RST_EDGE)
		if (`RST)	cam_data_i_d[7:1] <= 0;
		else 		cam_data_i_d[7:1] <= cam_data_i_d;
		
	
	
	wire		cam_vsync_falling = !cam_vsync_i_d[1] & cam_vsync_i_d[2];
	wire		cam_vsync_rising = cam_vsync_i_d[1] & !cam_vsync_i_d[2];
	wire		cam_href_falling = !cam_href_i_d[4] & cam_href_i_d[5];
	
	reg	capturing;
	reg	capture_start;
	
	always @(`CLK_RST_EDGE)
		if (`RST)		capture_start <= 0;
		else			capture_start <= cam_vsync_falling ;
	
	always @(`CLK_RST_EDGE)
		if (`RST)				capturing <= 0;
		else if (capture_start)	capturing <= 1;
		else if (capture_ready)	capturing <= 0;
	
	
	reg	[2:0]	scale_cnt_h;
	reg	[2:0]	scale_cnt_v;
	always @(`CLK_RST_EDGE)
		if (`RST)	scale_cnt_h <= 0;
		else if(cam_href_i_d[2])
			if (scale_cnt_h==cam_scale-1)	 
				scale_cnt_h <= 0;
			else 
				scale_cnt_h <= scale_cnt_h + 1;
		else 	scale_cnt_h <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)						scale_cnt_v <= 0;
		else if (cam_vsync_rising) 		scale_cnt_v <= 0;
		else if (cam_href_falling)		scale_cnt_v <= scale_cnt_v==cam_scale-1?  0 : scale_cnt_v + 1;
	
	
	wire	scale_he = scale_cnt_h==0;
	wire	scale_ve = scale_cnt_v == 0;
	wire	scale_e = scale_cnt_h==0 &&  scale_cnt_v  == 0;
	
	reg	[`W_PW:0]		cnt_h;
	reg	[`W_PH:0]		cnt_v;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_h <= 0;
		else 		cnt_h <= cam_href_i_d[2] ? cnt_h + scale_he : 0;
		
	always @(`CLK_RST_EDGE)
		if (`RST)								cnt_v <= 0;
		else if (cam_vsync_rising)				cnt_v <= 0;
		else if (cam_href_falling )				cnt_v <= cnt_v + scale_ve;
	
	reg	[`W_PW+1:0] 	x1;
	reg	[`W_PH+1:0] 	y1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	{x1, y1} <= 0;
		else begin
			x1 <= x + w;
			y1 <= y + h;		
		end
	reg		cnt_h_eq_x, cnt_h_eq_x1, cnt_v_eq_y, cnt_v_eq_y1;
	always @(`CLK_RST_EDGE)
		if (`RST)	{cnt_h_eq_x, cnt_h_eq_x1, cnt_v_eq_y, cnt_v_eq_y1} <= 0;
		else begin
			cnt_h_eq_x <=  cnt_h == x; 
			cnt_h_eq_x1 <=  cnt_h == x1; 
			cnt_v_eq_y <=  cnt_v == y; 
			cnt_v_eq_y1 <=  cnt_v == y1; 	
		end
	reg		hor_en, ver_en;
	always @(`CLK_RST_EDGE)
		if (`RST)					hor_en <= 0;
		else if (cnt_h_eq_x) 		hor_en <= 1;
		else if (cnt_h_eq_x1) 		hor_en <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)					ver_en <= 0;
		else if (cnt_v_eq_y)		ver_en <= 1;
		else if (cnt_v_eq_y1)		ver_en <= 0;
	wire	crop_en = hor_en & ver_en;
	
	//cam_href_i_d2
	// cnt_h
	// cnt_v       --  cnt_h_eq_x --> crop_en -->  cenb_frame_buf
	
	always @(`CLK_RST_EDGE)
		if (`RST)	capture_ready <= 0; 
		else 		capture_ready <= capturing & cnt_v_eq_y1 & cnt_h_eq_x1;
	
	always @(`CLK_RST_EDGE)
		if (`RST)					ab_frame_buf <= 0;
		else if (capture_start)		ab_frame_buf <= 0;
		else if (!cenb_frame_buf)	ab_frame_buf <= ab_frame_buf + 1;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cenb_frame_buf <= 1;
		else 		cenb_frame_buf <= !(capturing & crop_en);
		
	always @(`CLK_RST_EDGE)
		if (`RST)	db_frame_buf <= 0;
		else 		db_frame_buf <= cam_data_i_d[4];				
			
endmodule