module LCD_test(clk_i,cam_b,camera_e,rs_o,wr_o,reset_o,rd_o,data_o,rstsw_i);
	output 			rs_o,wr_o,reset_o,rd_o;
	output [7:0]	data_o;
	input 			clk_i,rstsw_i;
	input wire [15:0]cam_b;
	input wire camera_e;
	reg rs_o,cs_o,wr_o,reset_o,rd_o,read_f;
	reg lcdck,ck1s,ck1ms,ck50ms,ck200ms,rstflag,ckrst;
	reg [7:0]  data_o;
	reg [1:0]  lcdflag;
	reg [2:0]  cnt,part;
	reg [15:0] cnt1ms;
	reg [13:0]  cnt1s;
	reg [5:0]  cnt50ms;
	reg [1:0]  cnt200ms;
	reg [3:0]  lcdcnt1,lcdcnt3;
	reg [17:0] lcdcnt2;
	reg [7:0]  lcdcmd;
	reg [15:0] lcddt;


	wire clk_i,rstsw_i;


//lcd基準クロック10MHz作成
	always @(posedge clk_i or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			lcdck   <= 1'b0;	
			cnt     <= 3'b00;
		end
		else begin
			if(cnt == 3'b100)begin
			cnt <= 3'b000;
			lcdck <= 1'b1;
			end
			else begin
			cnt     <= cnt + 1'b1;
			lcdck   <= 1'b0;
			end
		end
	end

	
	//1sクロック作成
	always @(posedge ck1ms or posedge !rstsw_i or posedge ckrst)
	begin
		if(!rstsw_i || ckrst) begin
			ck1s   <= 1'b0;	
			cnt1s  <= 14'h0000;
		end
		else begin
			if(cnt1s == 14'h03e7) begin
				cnt1s <= 14'h0000;
				ck1s  <= 1'b1;
			end
			else begin
				cnt1s  <= cnt1s + 1'b1;
				ck1s   <= 1'b0;
			end
		end
	end
	//1msクロック作成
	always @(posedge clk_i or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			ck1ms   <= 1'b0;	
			cnt1ms  <= 16'h0000;
		end
		else begin
			if(cnt1ms == 16'hc350) begin
				cnt1ms <= 16'h0000;
				ck1ms  <= 1'b1;
			end
			else begin
				cnt1ms  <= cnt1ms + 1'b1;
				ck1ms   <= 1'b0;
			end
		end
	end

//50msクロック作成
	always @(posedge ck1ms or posedge !rstsw_i or posedge ckrst)
	begin
		if(!rstsw_i || ckrst) begin
			ck50ms   <= 1'b0;	
			cnt50ms  <= 6'h00;
		end
		else begin
			if(cnt50ms == 6'h32) begin
//			if(cnt50ms == 6'h03) begin
				cnt50ms <= 6'h00;
				ck50ms  <= 1'b1;
			end
			else begin
				cnt50ms  <= cnt50ms + 1'b1;
				ck50ms   <= 1'b0;
			end
		end
	end

//200msクロック作成
	always @(posedge ck50ms or posedge !rstsw_i or posedge ckrst)
	begin
		if(!rstsw_i || ckrst) begin
			ck200ms   <= 1'b0;	
			cnt200ms  <= 2'b00;
		end
		else begin
			if(cnt200ms == 2'b11) begin
				cnt200ms <= 2'b00;
				ck200ms  <= 1'b1;
			end
			else begin
				cnt200ms  <= cnt200ms + 1'b1;
				ck200ms   <= 1'b0;
			end
		end
	end

//ソフトウェアリセット
	always @(posedge ck1ms or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			reset_o  <= 1'b0;
			rstflag  <= 1'b0;
		end
		else begin
			if(rstflag == 1'b0) begin
				reset_o  <= 1'b1;
				if(ck200ms == 1'b1)
					rstflag <= 1'b1;
			end
		end
	end

//main
	always @(posedge clk_i or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			rd_o     <= 1'b1;
			lcdcnt1  <= 4'h0;
			lcdcnt3  <= 4'h0;
			lcdcnt2  <= 17'h00000;
			lcdflag  <= 2'b01;
			ckrst	   <= 1'b0;
		end
		else begin
			if(rstflag == 1'b1) begin
				case(lcdflag)
					2'b01	:begin
							case(lcdcnt2)
								17'h00001 : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h00002 : begin
											ckrst <= 1'b0;
											if(ck50ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h00003 : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h00004 : begin
											ckrst <= 1'b0;
											if(ck200ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h0000c : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h0000d : begin
											ckrst <= 1'b0;
											if(ck200ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h00064 : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h00065 : begin
											ckrst <= 1'b0;
											if(ck200ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h04066 : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h04067 : begin
											ckrst <= 1'b0;
											if(ck50ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h08068 : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h08069 : begin
											ckrst <= 1'b0;
											if(ck50ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h0c06a : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h0c06b : begin
											ckrst <= 1'b0;
											if(ck50ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h1006c : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h1006d : begin
											ckrst <= 1'b0;
											if(ck50ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h1406e : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h1406f : begin
											ckrst <= 1'b0;
											if(ck50ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h18070 : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h18071 : begin
											ckrst <= 1'b0;
											if(ck50ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								17'h1c072 : begin
											ckrst <= 1'b1;
											lcdcnt2 <= lcdcnt2 + 8'h1;
										end
								17'h1c073 : begin
											ckrst <= 1'b0;
											if(ck50ms == 1'b1) begin
												lcdcnt1 <= 4'h0;
												lcdcnt3 <= 4'h0;
												lcdcnt2 <= lcdcnt2 + 8'h1;
												lcdflag  <=  2'b10;
											end
										end
								

								18'h2006d : begin
								lcdcnt1 <= 4'h0;
										lcdcnt3 <= 4'h0;
								if(camera_e) begin
								   if(!read_f)begin
								   read_f <=1;
									lcdflag  <= 2'b10;
								   end
									end
									else read_f <=0;
								//lcdflag <= 2'b00;
								//lcdcnt2 <= 17'h00067;
								end
								default : begin
										lcdcnt1 <= 4'h0;
										lcdcnt3 <= 4'h0;
										lcdcnt2 <= lcdcnt2 + 8'h1;
										lcdflag  <= 2'b10;
									end
							endcase
						end
					2'b10	:begin
								if(part == 2'b01) begin
								if(lcdcnt1 == 4'h5)
									lcdflag <= 2'b01;
								else
									lcdcnt1 <= lcdcnt1 + 4'h1;
						end 
								else if(part == 2'b10) begin
								if(lcdcnt3 == 4'h3)
									lcdflag <= 2'b01;
								else
									lcdcnt3 <= lcdcnt3 + 4'h1;
									end
								else if(part == 2'b11||	part==3'b100) begin
								if(lcdcnt3 == 4'h6)
									lcdflag <= 2'b01;
								else
									lcdcnt3 <= lcdcnt3 + 4'h1;
						end
						end
				endcase
			end
		end
	end

//コマンド、データ作成
	always @(negedge clk_i or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			lcdcmd   <= 16'h0000;
			lcddt    <= 16'h0000;
		end
		else begin
			if(lcdflag == 2'b10) begin
			case(lcdcnt2)
				17'h00001	: begin
						lcdcmd  <= 8'h01;
						part <= 2'b01;
					end
				17'h00003	: begin
						lcdcmd  <= 8'h11;
						part <= 2'b01;
					end
				17'h00005	: begin
						lcdcmd  <= 8'hff;
						part <= 2'b01;
					end
				17'h00006	: begin
						lcddt  <= 8'h40;
						part <= 2'b10;
					end
				17'h00007	: begin
						lcddt   <= 8'h03;
						part <= 2'b10;
					end
				17'h00008	: begin
						lcddt   <= 8'h1a;
						part <= 2'b10;
					end
				17'h00009	: begin
						lcdcmd  <= 8'hd9;
						part <= 2'b01;
					end
				17'h0000a	: begin
						lcddt   <= 8'h60;
						part <= 2'b10;
					end
				17'h0000b	: begin
						lcdcmd  <= 8'hc7;
						part <= 2'b01;
					end
				17'h0000c	: begin
						lcddt   <= 8'h90;
						part <= 2'b10;
					end
				17'h0000e	: begin
						lcdcmd  <= 8'hb1;
						part <= 2'b01;
					end
				17'h0000f	: begin
						lcddt   <= 8'h04;
						part <= 2'b10;
					end
				17'h00010	: begin
						lcddt   <= 8'h25;
						part <= 2'b10;
					end
				17'h00011	: begin
						lcddt   <= 8'h18;
						part <= 2'b10;
					end
				17'h00012	: begin
						lcdcmd  <= 8'hb2;
						part <= 2'b01;
					end
				17'h00013	: begin
						lcddt  <= 8'h04;
						part <= 2'b10;
					end
				17'h00014	: begin
						lcddt  <= 8'h25;
						part <= 2'b10;
					end

				17'h00015	: begin
						lcddt  <= 8'h18;
						part <= 2'b10;
					end
				17'h00016	: begin
						lcdcmd  <= 8'hb3;
						part <= 2'b01;
					end				

				17'h00017	: begin
						lcddt  <= 8'h04;
						part <= 2'b10;
					end

				17'h00019	: begin
						lcddt  <= 8'h25;
						part <= 2'b10;
					end				
				17'h0001a	: begin
						lcddt  <= 8'h18;
						part <= 2'b10;
					end
				17'h0001b	: begin
						lcddt  <= 8'h04;
						part <= 2'b10;
					end

				17'h0001c	: begin
						lcddt  <= 8'h25;
						part <= 2'b10;
					end
				17'h0001d	: begin
						lcddt  <= 8'h18;
						part <= 2'b10;
					end
				17'h0001e	: begin
						lcdcmd  <= 8'hb4;
						part <= 2'b01;
					end
				17'h0001f	: begin
						lcddt  <= 8'h03;
						part <= 2'b10;
					end
				17'h00020	: begin
						lcdcmd  <= 8'hb6;
						part <= 2'b01;
					end
				17'h00021	: begin
						lcddt  <= 8'h15;
						part <= 2'b10;
					end
				17'h00022	: begin
						lcddt  <= 8'h02;
						part <= 2'b10;
					end
				17'h00023	: begin
						lcdcmd  <= 8'hc0;
						part <= 2'b01;
					end
				17'h00024	: begin
						lcddt  <= 8'h02;
						part <= 2'b10;
					end
				17'h00025	: begin
						lcddt  <= 8'h70;
						part <= 2'b10;
					end
				17'h00026	: begin
						lcdcmd  <= 8'hc1;
						part <= 2'b01;
					end
				17'h00027	: begin
						lcddt  <= 8'h07;
						part <= 2'b10;
					end
				17'h00028	: begin
						lcdcmd  <= 8'hc2;
						part <= 2'b01;
					end
				17'h00029	: begin
						lcddt  <= 8'h01;
						part <= 2'b10;
					end
				17'h0002a	: begin
						lcddt  <= 8'h01;
						part <= 2'b10;
					end
				17'h0002b	: begin
						lcdcmd  <= 8'hc3;
						part <= 2'b01;
					end
				17'h0002c	: begin
						lcddt  <= 8'h02;
						part <= 2'b10;
					end
				17'h0002d	: begin
						lcddt  <= 8'h07;
						part <= 2'b10;
					end
				17'h0002e	: begin
						lcdcmd  <= 8'hc4;
						part <= 2'b01;
					end
				17'h0002f	: begin
						lcddt  <= 8'h02;
						part <= 2'b10;
					end
				17'h00030	: begin
						lcddt  <= 8'h04;
						part <= 2'b10;
					end
				17'h00031	: begin
						lcdcmd  <= 8'hfc;
						part <= 2'b01;
					end
				17'h00032	: begin
						lcddt  <= 8'h11;
						part <= 2'b10;
					end
				17'h00033	: begin
						lcddt  <= 8'h17;
						part <= 2'b10;
					end
				17'h00034	: begin
						lcdcmd  <= 8'h36;
						part <= 2'b01;
					end
				17'h00035	: begin
						lcddt  <= 8'hc8;
						part <= 2'b10;
					end
				17'h00036	: begin
						lcdcmd  <= 8'h3a;
						part <= 2'b01;
					end
				17'h00037	: begin
						lcddt  <= 8'h05;
						part <= 2'b10;
					end
				17'h00038	: begin
						lcdcmd  <= 8'he0;
						part <= 2'b01;
					end
				17'h00039	: begin
						lcddt  <= 8'h06;
						part <= 2'b10;
					end
				17'h0003a	: begin
						lcddt  <= 8'h0e;
						part <= 2'b10;
					end
				17'h0003b	: begin
						lcddt  <= 8'h05;
						part <= 2'b10;
					end
				17'h0003c	: begin
						lcddt  <= 8'h20;
						part <= 2'b10;
					end
				17'h0003d	: begin
						lcddt  <= 8'h27;
						part <= 2'b10;
					end
				17'h0003e	: begin
						lcddt  <= 8'h23;
						part <= 2'b10;
					end
				17'h0003f	: begin
						lcddt  <= 8'h1c;
						part <= 2'b10;
					end
				17'h00040	: begin
						lcddt  <= 8'h21;
						part <= 2'b10;
					end
				17'h00041	: begin
						lcddt  <= 8'h20;
						part <= 2'b10;
					end
				17'h00042	: begin
						lcddt  <= 8'h1c;
						part <= 2'b10;
					end
				17'h00043	: begin
						lcddt  <= 8'h26;
						part <= 2'b10;
					end
				17'h00044	: begin
						lcddt  <= 8'h2f;
						part <= 2'b10;
					end
				17'h00045	: begin
						lcddt  <= 8'h00;
						part <= 2'b10;
					end
				17'h00046	: begin
						lcddt  <= 8'h03;
						part <= 2'b10;
					end
				17'h00047	: begin
						lcddt  <= 8'h00;
						part <= 2'b10;
					end
				17'h00048	: begin
						lcddt  <= 8'h24;
						part <= 2'b10;
					end
				17'h00049	: begin
						lcdcmd  <= 8'he1;
						part <= 2'b01;
					end
				17'h0004a	: begin
						lcddt  <= 8'h06;
						part <= 2'b10;
					end
				17'h0004b	: begin
						lcddt  <= 8'h10;
						part <= 2'b10;
					end
				17'h0004c	: begin
						lcddt  <= 8'h05;
						part <= 2'b10;
					end
				17'h0004d	: begin
						lcddt  <= 8'h21;
						part <= 2'b10;
					end
				17'h0004e	: begin
						lcddt  <= 8'h27;
						part <= 2'b10;
					end
				17'h0004f	: begin
						lcddt  <= 8'h22;
						part <= 2'b10;
					end
				17'h00050	: begin
						lcddt  <= 8'h1c;
						part <= 2'b10;
					end
				17'h00051	: begin
						lcddt  <= 8'h21;
						part <= 2'b10;
					end
				17'h00052	: begin
						lcddt  <= 8'h1f;
						part <= 2'b10;
					end
				17'h00053	: begin
						lcddt  <= 8'h1d;
						part <= 2'b10;
					end
				17'h00054	: begin
						lcddt  <= 8'h27;
						part <= 2'b10;
					end
				17'h00055	: begin
						lcddt  <= 8'h2f;
						part <= 2'b10;
					end
				17'h00056	: begin
						lcddt  <= 8'h05;
						part <= 2'b10;
					end
				17'h00057	: begin
						lcddt  <= 8'h03;
						part <= 2'b10;
					end
				17'h00058	: begin
						lcddt  <= 8'h00;
						part <= 2'b10;
					end
				17'h00059	: begin
						lcddt  <= 8'h3f;
						part <= 2'b10;
					end
				17'h0005a	: begin
						lcdcmd  <= 8'h2a;
						part <= 2'b01;
					end
				17'h0005b	: begin
						lcddt  <= 8'h00;
						part <= 2'b10;
					end
				17'h0005c	: begin
						lcddt  <= 8'h02;
						part <= 2'b10;
					end
				17'h0005d	: begin
						lcddt  <= 8'h00;
						part <= 2'b10;
					end
				17'h0005e	: begin
						lcddt  <= 8'h81;
						part <= 2'b10;
					end
				17'h0005f	: begin
						lcdcmd  <= 8'h2b;
						part <= 2'b01;
					end
				17'h00060	: begin
						lcddt  <= 8'h00;
						part <= 2'b10;
					end
				17'h00061	: begin
						lcddt  <= 8'h03;
						part <= 2'b10;
					end
				17'h00062	: begin
						lcddt  <= 8'h00;
						part <= 2'b10;
					end
				17'h00063	: begin
						lcddt  <= 8'h82;
						part <= 2'b10;
					end
				17'h00064	: begin
						lcdcmd  <= 8'h29;
						part <= 2'b01;
					end
				17'h00066	: begin
						lcdcmd  <= 8'h2c;
						part <= 2'b01;
					end
				
				default : begin
						if((lcdcnt2 > 17'h00066) && (lcdcnt2 < 17'h04066))
						begin
							part <= 2'b11;
							lcddt   <= 16'h0000;
						end
						else if((lcdcnt2 > 17'h04067) && (lcdcnt2 < 17'h08068))
						begin
							
							lcddt   <= 16'hf800;
						end
						else if((lcdcnt2 > 17'h08069) && (lcdcnt2 < 17'h0c06a))
						begin
							lcddt   <= 16'h07e0;
						end
						else if((lcdcnt2 > 17'h0c06b) && (lcdcnt2 < 17'h1006c))
						begin
							lcddt   <= 16'h001f;
						end
						else if((lcdcnt2 > 17'h1006d) && (lcdcnt2 < 17'h1406e))
						begin
							lcddt   <= 16'hffe0;
						end
						else if((lcdcnt2 > 18'h1406f) && (lcdcnt2 < 18'h18070))
						begin
							lcddt   <= 16'he011;
						end
						else if((lcdcnt2 > 18'h18071) && (lcdcnt2 < 18'h1c072))
						begin
							lcddt   <= 16'h7bef;
						end
						else if((lcdcnt2 > 18'h1c073) && (lcdcnt2 < 18'h2006c))
						begin
							lcddt   <= 16'hffff;
						end
						else if(lcdcnt2 == 18'h2006c)
						begin
							part <= 3'b010;
							lcddt<= 8'h00;
						end
						else if(lcdcnt2 == 18'h2006d)
						begin
							part <= 3'b100;
						end
						
						else begin
							//lcdcnt2 <= 17'h00067;
							lcdcmd  <= 8'h00;
							lcddt   <= 16'h0000;
							//part <= 3'b100;
						end
					end
			endcase
			end
		end
	end

//LCDレジスタ設定、データ設定
	always @(negedge clk_i or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			data_o   <= 8'h00;
			rs_o     <= 1'b1;
			//cs_o     <= 1'b1;
			wr_o	   <= 1'b1;
		end
		else begin
			if(lcdflag == 2'b10) begin
				if(part==2'b01) begin
			case(lcdcnt1)
				4'h0	: cs_o   <= 1'b0;
				4'h1	: rs_o   <= 1'b0;
				4'h2	: data_o <= lcdcmd[7:0];
				4'h3	: wr_o   <= 1'b0;
				4'h4	: wr_o   <= 1'b1;
				4'h5	: rs_o   <= 1'b1;
			endcase
			end
				else if(part==2'b10) begin
			case(lcdcnt3) 
				4'h0	: cs_o   <= 1'b0;
				4'h1	: data_o <= lcddt[7:0];
				4'h2	: wr_o   <= 1'b0;
				4'h3	: wr_o   <= 1'b1;
					
			endcase
			end
				else if(part==2'b11) begin
			case(lcdcnt3) 
				4'h0	: cs_o   <= 1'b0;
				4'h1	: data_o <= lcddt[15:8];
				4'h2	: wr_o   <= 1'b0;
				4'h3	: wr_o   <= 1'b1;
				4'h4	: data_o <= lcddt[7:0];
				4'h5	: wr_o   <= 1'b0;
				4'h6	: wr_o   <= 1'b1;
					
			endcase
			end
				else if(part==3'b100) begin
			case(lcdcnt3) 
				4'h0	: cs_o   <= 1'b0;
				4'h1	: data_o <= cam_b[15:8];
				4'h2	: wr_o   <= 1'b0;
				4'h3	: wr_o   <= 1'b1;
				4'h4	: data_o <= cam_b[7:0];
				4'h5	: wr_o   <= 1'b0;
				4'h6	: wr_o   <= 1'b1;
					
			endcase
			end
			end
		end
	end
endmodule

