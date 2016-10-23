module sccb(clk_i,rstsw_i,SDA,SCL);
	output 			SDA,SCL;
	input 			clk_i,rstsw_i;
	reg SDA,SCL;
	reg m10ck,sccbck,ck1ms,ck10ms,ck50ms,ck200ms,rstflag,ckrst;
	reg [1:0]  sccbflag;
	reg [2:0]  cnt10m;
	reg [4:0]  cnt1m;
	reg [13:0] cnt1ms;
	reg [13:0]  cnt1s;
	reg [5:0]  cnt50ms;
	reg [1:0]  cnt200ms;
	reg [8:0]  sccbcnt;
	reg [17:0] sccb_init_cnt;
	reg [7:0]  data;
	reg [7:0] adrs;


	wire clk_i,rstsw_i;


//10MHz作成
	always @(posedge clk_i or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			m10ck   <= 1'b0;	
			cnt10m     <= 3'b00;
		end
		else begin
			if(cnt10m == 3'b100)begin
			cnt10m = 3'b000;
			m10ck <= 1'b1;
			end
			else begin
			cnt10m     <= cnt10m + 1'b1;
			m10ck   <= 1'b0;
			end
		end
	end
	
//0.5MHz_for_sccb
	always @(posedge m10ck or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			sccbck   <= 1'b0;	
			cnt1m     <= 3'b000;
		end
		else begin
			if(cnt1m == 5'h14)begin
			cnt1m     <= 5'h00;
			sccbck <= 1'b1;
			end
			else begin
			cnt1m     <= cnt1m + 1'b1;
			sccbck   <= 1'b0;
			end
		end
	end
		//1msクロック作成
	always @(posedge m10ck or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			ck1ms   <= 1'b0;	
			cnt1ms  <= 14'h0000;
		end
		else begin
			if(cnt1ms == 14'h2710) begin
				cnt1ms <= 14'h0000;
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
	
	
	always @(posedge sccbck or posedge !rstsw_i)	
	begin
		if(!rstsw_i) begin
			sccbcnt  <= 8'h00;
			sccb_init_cnt  <= 17'h00000;
			sccbflag  <= 2'b01;
			ckrst	   <= 1'b0;
			rstflag <= 1'b1;
		end
		else begin
			if(rstflag == 1'b1) begin
				case(sccbflag)
					2'b01	:begin
							case(sccb_init_cnt)
								17'h00001 : begin
											ckrst <= 1'b1;
											sccb_init_cnt <= sccb_init_cnt + 8'h1;
										end
								17'h00002 : begin
											ckrst <= 1'b0;
											if(ck200ms == 1'b1) begin
												sccbcnt <= 8'h00;
												sccb_init_cnt <= sccb_init_cnt + 8'h1;
												sccbflag  <=  2'b10;
											end
										end
								default : begin
										sccbcnt <= 8'h00;
										if (sccb_init_cnt < 17'h0006f) begin
										sccb_init_cnt <= sccb_init_cnt + 8'h1;
										
										 sccbflag  <= 2'b10;
										 end
									end
							endcase
						end
					2'b10	:begin
								
								if(sccbcnt == 8'h56)
									sccbflag <= 2'b01;
								else
								
									sccbcnt <= sccbcnt + 8'h01;
									end
								
				endcase
			end
		end
	end

	//コマンド、データ作成
	always @(negedge sccbck or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			data   <= 8'h00;
			adrs   <= 8'h00;
		end
		else begin
			if(sccbflag == 2'b10) begin
			case(sccb_init_cnt)
				17'h00001	: begin
						adrs  <= 8'h12;
						data  <= 8'h80;
					end
				17'h00003	: begin
						adrs  <= 8'h12;
						data  <= 8'h0c;
					end
				17'h00004	: begin
						adrs  <= 8'h8c;
						data  <= 8'h00;
					end
				17'h00005	: begin
						adrs  <= 8'h04;
						data  <= 8'h00;
					end
				17'h00006	: begin
						adrs  <= 8'h40;
						data  <= 8'h90;
					end
				17'h00007	: begin
						adrs  <= 8'h14;
						data  <= 8'h08;
					end
				17'h00008	: begin
						adrs  <= 8'haa;
						data  <= 8'h94;
					end
				17'h00009	: begin
						adrs  <= 8'h3a;
						data  <= 8'h04;
					end
				17'h0000a	: begin
						adrs  <= 8'h20;
						data  <= 8'h04;
					end
				17'h0000b	: begin
						adrs  <= 8'h13;
						data  <= 8'hfd;
					end
				17'h0000c	: begin
						adrs  <= 8'h10;
						data  <= 8'h0f;
					end
				17'h0000d	: begin
						adrs  <= 8'h07;
						data  <= 8'h00;
					end
				17'h0000e	: begin
						adrs  <= 8'h01;
						data  <= 8'h40;
					end
				17'h0000f	: begin
						adrs  <= 8'h02;
						data  <= 8'h60;
					end
				17'h00010	: begin
						adrs  <= 8'h03;
						data  <= 8'h0a;
					end
				17'h00011	: begin
						adrs  <= 8'h0c;
						data  <= 8'h00;
					end
				17'h00012	: begin
						adrs  <= 8'h0e;
						data  <= 8'h61;
					end
				17'h00013	: begin
						adrs  <= 8'h0f;
						data  <= 8'h4b;
					end
				17'h00014	: begin
						adrs  <= 8'h15;
						data  <= 8'h00;
					end
				17'h00015	: begin
						adrs  <= 8'h16;
						data  <= 8'h02;
					end
				17'h00016	: begin
						adrs  <= 8'h17;
						data  <= 8'h18;
					end
				17'h00017	: begin
						adrs  <= 8'h18;
						data  <= 8'h01;
					end
				17'h00018	: begin
						adrs  <= 8'h19;
						data  <= 8'h02;
					end
				17'h00019	: begin
						adrs  <= 8'h1a;
						data  <= 8'h7a;
					end
				17'h0001a	: begin
						adrs  <= 8'h1e;
						data  <= 8'h07;
					end
				17'h0001b	: begin
						adrs  <= 8'h21;
						data  <= 8'h02;
					end
				17'h0001c	: begin
						adrs  <= 8'h22;
						data  <= 8'h91;
					end
				17'h0001d	: begin
						adrs  <= 8'h29;
						data  <= 8'h07;
					end
				17'h0001e	: begin
						adrs  <= 8'h32;
						data  <= 8'hb6;
					end
				17'h0001f	: begin
						adrs  <= 8'h33;
						data  <= 8'h0b;
					end
				17'h00020	: begin
						adrs  <= 8'h34;
						data  <= 8'h11;
					end
				17'h00021	: begin
						adrs  <= 8'h35;
						data  <= 8'h0b;
					end
				17'h00022	: begin
						adrs  <= 8'h37;
						data  <= 8'h1d;
					end
				17'h00023	: begin
						adrs  <= 8'h38;
						data  <= 8'h71;
					end
				17'h00024	: begin
						adrs  <= 8'h39;
						data  <= 8'h2a;
					end
				17'h00025	: begin
						adrs  <= 8'h3b;
						data  <= 8'h92;
					end
				17'h00026	: begin
						adrs  <= 8'h3c;
						data  <= 8'h78;
					end
				17'h00027	: begin
						adrs  <= 8'h3d;
						data  <= 8'hc3;
					end
				17'h00028	: begin
						adrs  <= 8'h3e;
						data  <= 8'h00;
					end
				17'h00029	: begin
						adrs  <= 8'h3f;
						data  <= 8'h00;
					end
				17'h0002a	: begin
						adrs  <= 8'h41;
						data  <= 8'h08;
					end
				17'h0002b	: begin
						adrs  <= 8'h41;
						data  <= 8'h38;
					end
				17'h0002c	: begin
						adrs  <= 8'h43;
						data  <= 8'h0a;
					end
				17'h0002d	: begin
						adrs  <= 8'h44;
						data  <= 8'hf0;
					end
				17'h0002e	: begin
						adrs  <= 8'h45;
						data  <= 8'h34;
					end
				17'h0002f	: begin
						adrs  <= 8'h46;
						data  <= 8'h58;
					end
				17'h00030	: begin
						adrs  <= 8'h47;
						data  <= 8'h28;
					end
				17'h00031	: begin
						adrs  <= 8'h48;
						data  <= 8'h3a;
					end
				17'h00032	: begin
						adrs  <= 8'h4b;
						data  <= 8'h09;
					end
				17'h00033	: begin
						adrs  <= 8'h4c;
						data  <= 8'h00;
					end
				17'h00034	: begin
						adrs  <= 8'h4d;
						data  <= 8'h40;
					end
				17'h00035	: begin
						adrs  <= 8'h4e;
						data  <= 8'h20;
					end
				17'h00036	: begin
						adrs  <= 8'h4f;
						data  <= 8'h80;
					end
				17'h00037	: begin
						adrs  <= 8'h50;
						data  <= 8'h80;
					end
				17'h00038	: begin
						adrs  <= 8'h51;
						data  <= 8'h00;
					end
				17'h00039	: begin
						adrs  <= 8'h52;
						data  <= 8'h22;
					end
				17'h0003a	: begin
						adrs  <= 8'h53;
						data  <= 8'h5e;
					end
				17'h0003b	: begin
						adrs  <= 8'h54;
						data  <= 8'h80;
					end
				17'h0003c	: begin
						adrs  <= 8'h56;
						data  <= 8'h40;
					end
				17'h0003d	: begin
						adrs  <= 8'h58;
						data  <= 8'h9e;
					end
				17'h0003e	: begin
						adrs  <= 8'h59;
						data  <= 8'h88;
					end
				17'h0003f	: begin
						adrs  <= 8'h5a;
						data  <= 8'h88;
					end
				17'h00040	: begin
						adrs  <= 8'h5b;
						data  <= 8'h44;
					end
				17'h00041	: begin
						adrs  <= 8'h5c;
						data  <= 8'h67;
					end
				17'h00042	: begin
						adrs  <= 8'h5d;
						data  <= 8'h49;
					end
				17'h00043	: begin
						adrs  <= 8'h5e;
						data  <= 8'h0e;
					end
				17'h00044	: begin
						adrs  <= 8'h69;
						data  <= 8'h00;
					end
				17'h00045	: begin
						adrs  <= 8'h6a;
						data  <= 8'h40;
					end
				17'h00046	: begin
						adrs  <= 8'h6b;
						data  <= 8'h0a;
					end
				17'h00047	: begin
						adrs  <= 8'h6c;
						data  <= 8'h0a;
					end
				17'h00048	: begin
						adrs  <= 8'h6d;
						data  <= 8'h55;
					end
				17'h00049	: begin
						adrs  <= 8'h6e;
						data  <= 8'h11;
					end
				17'h0004a	: begin
						adrs  <= 8'h6f;
						data  <= 8'h9f;
					end
				17'h0004b	: begin
						adrs  <= 8'h70;
						data  <= 8'h3a;
					end
				17'h0004c	: begin
						adrs  <= 8'h71;
						data  <= 8'h35;
					end
				17'h0004d	: begin
						adrs  <= 8'h72;
						data  <= 8'h11;
					end
				17'h0004e	: begin
						adrs  <= 8'h73;
						data  <= 8'hf0;
					end
				17'h0004f	: begin
						adrs  <= 8'h74;
						data  <= 8'h10;
					end
				17'h00050	: begin
						adrs  <= 8'h75;
						data  <= 8'h05;
					end
				17'h00051	: begin
						adrs  <= 8'h76;
						data  <= 8'he1;
					end
				17'h00052	: begin
						adrs  <= 8'h77;
						data  <= 8'h01;
					end
				17'h00053	: begin
						adrs  <= 8'h78;
						data  <= 8'h04;
					end
				17'h00054	: begin
						adrs  <= 8'h79;
						data  <= 8'h01;
					end
				17'h00055	: begin
						adrs  <= 8'h8d;
						data  <= 8'h4f;
					end
				17'h00056	: begin
						adrs  <= 8'h8e;
						data  <= 8'h00;
					end
				17'h00057	: begin
						adrs  <= 8'h8f;
						data  <= 8'h00;
					end
				17'h00058	: begin
						adrs  <= 8'h90;
						data  <= 8'h00;
					end
				17'h00059	: begin
						adrs  <= 8'h91;
						data  <= 8'h00;
					end
				17'h0005a	: begin
						adrs  <= 8'h96;
						data  <= 8'h00;
					end
				17'h0005b	: begin
						adrs  <= 8'h96;
						data  <= 8'h00;
					end
				17'h0005c	: begin
						adrs  <= 8'h97;
						data  <= 8'h30;
					end
				17'h0005d	: begin
						adrs  <= 8'h98;
						data  <= 8'h20;
					end
				17'h0005e	: begin
						adrs  <= 8'h99;
						data  <= 8'h30;
					end
				17'h0005f	: begin
						adrs  <= 8'h9a;
						data  <= 8'h00;
					end
				17'h00060	: begin
						adrs  <= 8'h9a;
						data  <= 8'h84;
					end
				17'h00061	: begin
						adrs  <= 8'h9b;
						data  <= 8'h29;
					end
				17'h00062	: begin
						adrs  <= 8'h9c;
						data  <= 8'h03;
					end
				17'h00063	: begin
						adrs  <= 8'h9d;
						data  <= 8'h4c;
					end
				17'h00064	: begin
						adrs  <= 8'h9e;
						data  <= 8'h3f;
					end
				17'h00065	: begin
						adrs  <= 8'ha2;
						data  <= 8'h02;
					end
				17'h00066	: begin
						adrs  <= 8'ha4;
						data  <= 8'h88;
					end
				17'h00067	: begin
						adrs  <= 8'hb0;
						data  <= 8'h84;
					end
				17'h00068	: begin
						adrs  <= 8'hb1;
						data  <= 8'h0c;
					end
				17'h00069	: begin
						adrs  <= 8'hb2;
						data  <= 8'h0e;
					end
				17'h0006a	: begin
						adrs  <= 8'hb3;
						data  <= 8'h82;
					end
				17'h0006b	: begin
						adrs  <= 8'hb8;
						data  <= 8'h0a;
					end
				17'h0006c	: begin
						adrs  <= 8'hc8;
						data  <= 8'hf0;
					end
				17'h0006d	: begin
						adrs  <= 8'hc9;
						data  <= 8'h60;
					end
				17'h0006e	: begin
						adrs  <= 8'h6b;
						data  <= 8'h00;
					end
				17'h0006f	: begin
						adrs  <= 8'h11;
						data  <= 8'h40;
					end
				endcase
			end
		end
	end
	
	
	always @(negedge sccbck or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			//data   <= 8'h00;
			//adrs   <= 8'h00;
		end
		else begin
			if(sccbflag == 2'b10) begin
/**********************start**********************/				
			case(sccbcnt)
				8'h00	: begin	
						SDA <= 1'b1;
						SCL <= 1'b1;
						end
				8'h01	: SDA <= 1'b0;
				8'h02	: begin
						SCL <= 1'b0;
						SDA <= 1'b0;
						end
				8'h03	: SCL <= 1'b1;
				8'h04	: SCL <= 1'b0;
				8'h05	: begin
						SCL <= 1'b0;
						SDA <= 1'b1;
						end
				8'h06	: SCL <= 1'b1;
				8'h07	: SCL <= 1'b0;
				8'h08	:  begin
						SCL <= 1'b0;
						SDA <= 1'b0;
						end
				8'h09	: SCL <= 1'b1;
				8'h0a	: SCL <= 1'b0;
				8'h0b	:  begin
						SCL <= 1'b0;
						SDA <= 1'b0;
						end
				8'h0c	: SCL <= 1'b1;
				8'h0d	: SCL <= 1'b0;
				8'h0e	:  begin
						SCL <= 1'b0;
						SDA <= 1'b0;
						end
				8'h0f	: SCL <= 1'b1;
				8'h10	: SCL <= 1'b0;
				8'h11	:  begin
						SCL <= 1'b0;
						SDA <= 1'b0;
						end
				8'h12	: SCL <= 1'b1;
				8'h13	: SCL <= 1'b0;
				8'h14	:  begin
						SCL <= 1'b0;
						SDA <= 1'b1;
						end
				8'h15	: SCL <= 1'b1;
				8'h16	: SCL <= 1'b0;
				8'h17	:  begin
						SCL <= 1'b0;
						SDA <= 1'b0;
						end
				8'h18	: SCL <= 1'b1;
				8'h19	: SCL <= 1'b0;
				8'h1b	: SCL <= 1'b1;
				8'h1c	: SCL <= 1'b0;
				8'h1d	: begin
						SCL <= 1'b0;
						if(adrs & 8'h80) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h1e	: SCL <= 1'b1;
				8'h1f	: SCL <= 1'b0;
				8'h20	: begin
						SCL <= 1'b0;
						if(adrs & 8'h40) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h21	: SCL <= 1'b1;
				8'h22	: SCL <= 1'b0;				
				8'h23	: begin
						SCL <= 1'b0;
						if(adrs & 8'h20) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h24	: SCL <= 1'b1;
				8'h25	: SCL <= 1'b0;
				8'h26	: begin
						SCL <= 1'b0;
						if(adrs & 8'h10) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h27	: SCL <= 1'b1;
				8'h28	: SCL <= 1'b0;
				8'h29	: begin
						SCL <= 1'b0;
						if(adrs & 8'h08) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h2a	: SCL <= 1'b1;
				8'h2b	: SCL <= 1'b0;
				8'h2c	: begin
						SCL <= 1'b0;
						if(adrs & 8'h04) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h2d	: SCL <= 1'b1;
				8'h2e	: SCL <= 1'b0;
				8'h2f	: begin
						SCL <= 1'b0;
						if(adrs & 8'h02) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h30	: SCL <= 1'b1;
				8'h31	: SCL <= 1'b0;
				8'h32	: begin
						SCL <= 1'b0;
						if(adrs & 8'h01) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h33	: SCL <= 1'b1;
				8'h34	: SCL <= 1'b0;
				8'h36	: SCL <= 1'b1;
				8'h37	: SCL <= 1'b0;
				8'h38	: begin
						SCL <= 1'b0;
						if(data & 8'h80) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h39	: SCL <= 1'b1;
				8'h3a	: SCL <= 1'b0;
				8'h3b	: begin
						SCL <= 1'b0;
						if(data & 8'h40) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h3c	: SCL <= 1'b1;
				8'h3d	: SCL <= 1'b0;				
				8'h3e	: begin
						SCL <= 1'b0;
						if(data & 8'h20) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h3f	: SCL <= 1'b1;
				8'h40	: SCL <= 1'b0;
				8'h41	: begin
						SCL <= 1'b0;
						if(data & 8'h10) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h42	: SCL <= 1'b1;
				8'h43	: SCL <= 1'b0;
				8'h44	: begin
						SCL <= 1'b0;
						if(data & 8'h08) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h45	: SCL <= 1'b1;
				8'h46	: SCL <= 1'b0;
				8'h47	: begin
						SCL <= 1'b0;
						if(data & 8'h04) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h48	: SCL <= 1'b1;
				8'h49	: SCL <= 1'b0;
				8'h4a	: begin
						SCL <= 1'b0;
						if(data & 8'h02) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h4b	: SCL <= 1'b1;
				8'h4c	: SCL <= 1'b0;
				8'h4d	: begin
						SCL <= 1'b0;
						if(data & 8'h01) SDA <= 1'b1;
						else SDA <= 1'b0;
						end
				8'h4e	: SCL <= 1'b1;
				8'h4f	: SCL <= 1'b0;
				8'h51	: SCL <= 1'b1;
				8'h52	: SCL <= 1'b0;

				
				
				8'h53	: SCL <= 1'b0;
				8'h54	: SDA <= 1'b0;
				8'h55	: SCL <= 1'b1;
				8'h56	: SDA <= 1'b1;
		
			endcase
			end
	
		end
	end
	
	endmodule
	
