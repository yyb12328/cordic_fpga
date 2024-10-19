`timescale 1ns/1ns

module tb_sinh_cosh();

parameter PERIOD = 10;
reg clk;
reg rst_n;
reg pre_vaild;
reg signed [8+15:0] iData;

wire signed [24+15:0] 		sinh;
wire signed [24+15:0] 		cosh;
wire        post_vaild;

initial begin
	clk = 0;
	rst_n <= 0;
	iData <= 'b0;
    pre_vaild <= 1'b0;

	#100 rst_n <=1;
			
	#10 @(posedge clk) pre_vaild <= 1'b1;iData <= $signed(65536)/2;
    
	#10 @(posedge clk) 				    iData <=  $signed(65536)/3;
    #10 @(posedge clk) 				    iData <=  $signed(65536)*5;
    #10 @(posedge clk) 				    iData <=  $signed(65536)*10;
    #10 @(posedge clk) 				    iData <= $signed(65536)*15;
    #10 @(posedge clk)pre_vaild <= 1'b0;
    
    #200@(posedge clk)pre_vaild <= 1'b1; iData <= -$signed(65536)/2;
    
    #10 @(posedge clk) 				    iData <= -$signed(65536)/3;
    #10 @(posedge clk) 				    iData <= -$signed(65536)*5;
    #10 @(posedge clk) 				    iData <= -$signed(65536)*10;
    #10 @(posedge clk) 				    iData <= -$signed(65536)*15;
	#10 @(posedge clk)pre_vaild <= 1'b0;
	#100000 $stop;	
end

always #(PERIOD/2) clk = ~clk;

cordic_sinh_cosh_plus
#(    
    .WII       (8),
    .WOI       (24),
    .PIPELINE  (16)                        //pipe数，最大支持16
)cordic_sinh_cosh_plus
(
    .clk         (clk       ),
    .rst_n       (rst_n     ),
                            
    .alpha       (iData     ),   //16位小数位,-1.13~1.13    
    .pre_vaild   (pre_vaild ),
                            
    .sinh        (sinh      ), 
    .cosh        (cosh      ),
    .post_vaild  (post_vaild)

);//延迟PIPELINE+2拍

endmodule

