`timescale 1ns/1ns

module tb();

parameter PERIOD = 10;
reg clk;
reg rst_n;
reg pre_vaild;
reg signed [31:0] angle;

wire signed [31:0] 		sin;
wire signed [31:0] 		cos;
wire        post_vaild;

initial begin
	clk = 0;
	rst_n <= 0;
	angle <= 'b0;
    pre_vaild <= 1'b0;

	#100 rst_n <=1;
			
	#10 @(posedge clk) 
            pre_vaild <= 1'b1;
            angle <= 32'sd60 * $signed(65536);
    
	#10 @(posedge clk) 				    angle <= 32'sd30 * $signed(65536);
    #10 @(posedge clk) 				    angle <= 32'sd90 * $signed(65536);
    #10 @(posedge clk) 				    angle <= 32'sd120* $signed(65536);
    #10 @(posedge clk) 				    angle <= 32'sd150* $signed(65536);
    #10 @(posedge clk)pre_vaild <= 1'b0;
    
    #200@(posedge clk)
        pre_vaild <= 1'b1; 
        angle <= -32'sd30* $signed(65536);
    
    #10 @(posedge clk) 				    angle <= -32'sd60* $signed(65536);
    #10 @(posedge clk) 				    angle <= -32'sd90* $signed(65536);
    #10 @(posedge clk) 				    angle <= -32'sd120* $signed(65536);
    #10 @(posedge clk) 				    angle <= -32'sd150* $signed(65536);
	#10 @(posedge clk)pre_vaild <= 1'b0;
	#100000 $stop;	
end

always #(PERIOD/2) clk = ~clk;

cordic_sin_cos
#(    
    .PIPELINE(16)                        //pipe数，最大支持16
)cordic_sin_cos
(
    .clk        (clk  ),
    .rst_n      (rst_n),
                
    .angle      (angle),      //角度输入，16位小数位
    .pre_vaild  (pre_vaild),
                
    .sin        (sin), 
    .cos        (cos),
    .post_vaild (post_vaild)

);

endmodule

