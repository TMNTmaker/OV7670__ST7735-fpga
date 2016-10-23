module ov7670_module(test_led2,test_led1,test_led,data_o,rs_o,wr_o,reset_o,rd_o,SDA,SCL,HREF,VSYNC,PCLK,XCLK,data_i,clk_i,rstsw_i);
	output  			rs_o,wr_o,reset_o,rd_o;
	output  [7:0]	data_o;
	output reg XCLK;
	output  SDA,SCL;
	output reg test_led=0,test_led1=0,test_led2=0;
	reg [15:0] data; 
	input wire [7:0] data_i;
	input  clk_i,rstsw_i,HREF,VSYNC,PCLK;
	//wire clk_i,rstsw_i,HREF,VSYNC,PCLK;
	reg   startflag=0,hflag=0;
	reg   [5:0]Xcnt = 1'b0;
	reg   b_c = 1'b0;
	
	reg tck1s =0,tck1ms=0;
	reg tckrst=1'b1;
	reg [15:0]tcnt1s=0,tcnt1ms=0;
	reg [8:0]c= 9'h0;
	reg [6:0]r= 7'h0;
	
	LCD_test LCD_test1(.clk_i(clk_i),.cam_b(data),.camera_e(b_c),.rs_o(rs_o),.wr_o(wr_o),.reset_o(reset_o),.rd_o(rd_o),.data_o(data_o),.rstsw_i(rstsw_i));
   sccb sccb1(.clk_i(clk_i),.rstsw_i(rstsw_i),.SDA(SDA),.SCL(SCL));	
	//25MHz
	always @(posedge clk_i or posedge !rstsw_i)
	begin
		if(!rstsw_i) begin
			XCLK   <= 1'b0;	
			Xcnt     <= 1'b0;
		end
		else begin
			if(Xcnt == 6'h0)begin
			Xcnt <= 6'b0;
			XCLK <= ~XCLK;
			end
			else begin
			Xcnt     <= Xcnt + 6'b1;
			//XCLK <= 1'b0;
			end
		end
	end
	
		always @(posedge clk_i or posedge !rstsw_i or posedge tckrst)
	begin
		if(!rstsw_i|| tckrst) begin
		   
			tck1ms   <= 1'b0;	
			tcnt1ms  <= 16'h0000;
		end
		else begin
			if(tcnt1ms == 16'hc350) begin
				tcnt1ms <= 16'h0000;
				tck1ms  <= 1'b1;
				
			end
			else begin
				tcnt1ms  <= tcnt1ms + 1'b1;
				tck1ms   <= 1'b0;
			end
		end
	end
	
	always @(posedge tck1ms or posedge !rstsw_i or posedge tckrst)
	begin
		if(!rstsw_i || tckrst) begin
		   
			tck1s   <= 1'b0;	
			tcnt1s  <= 16'h0000;
		end
		else begin
			if(tcnt1s == 16'h2710) begin//03e8
				//tcnt1s <= 16'h0000;
				tck1s  <= 1'b1;
				
			end
			else begin
				tcnt1s  <= tcnt1s + 1'b1;
				tck1s   <= 1'b0;
			end
		end
	end
	
	
	always @(posedge PCLK or posedge !rstsw_i)
	begin
		
		if(!rstsw_i)begin 
			tckrst <=1'b1;
			
			//test_led <= 0;
			test_led1 <= 0;
			test_led2 <= 0;
		end
		
		
	
		else if(PCLK) begin
			if(HREF) begin
				hflag <= 0;
				if (startflag) begin 
					if(!(c == 9'h100)) begin  
						test_led1<=1;
						if(b_c == 1'b0) begin
							data[7:0] <= data_i;
							b_c <= 1'b1;
						end
						else if(b_c == 1'b1) begin 
							data[15:8] <= data_i;
							b_c <= 1'b0;
						end
						//b_c <= b_c + 1'b1;
						c <= c + 9'b1;
					end
					else test_led1<=0;
				
			end
			end //HREF
			
			else if(!HREF) begin 
				if(!hflag) begin 
					hflag<=1;
					if (startflag) begin  
						if(!(r == 8'h7f)) begin 
						   test_led2<=1; 
							c <= 9'h000; 
							r <= r + 8'h01;
						end 
						else begin 
							test_led2<=0; 
					startflag <=0; 
						end
				end 	
				end
				end
				
			//end
			
		 if(VSYNC) begin
			tckrst <=1'b0;
			if(tck1s == 1'b1) begin
			if(!startflag)begin
				startflag <= 1;
				test_led <= 1;
				r <= 8'h00;
				c <= 9'h000;
				end
			end 
			else begin test_led <= 0; startflag <= 0;end
		end
							
	end
	end
	
endmodule
	