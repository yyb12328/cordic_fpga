`timescale 1ns/1ns

module tb_2();

parameter PERIOD = 10;
reg clk;
reg rst_n;
reg pre_vaild;
reg signed [31:0] x;
reg signed [31:0] y;

wire signed [31:0] 		amplitude ;
wire signed [31:0] 		angle     ;
wire        post_vaild;

initial begin
	clk = 0;
	rst_n <= 0;
	x <= 0;
    y <= 0;
    pre_vaild <= 1'b0;

	#100 rst_n <=1;
			
	#10 @(posedge clk) 
            pre_vaild <= 1'b1;
            x <= 32'sd1 * $signed(65536);
            y <= 32'sd1 * $signed(65536);
    
	#10 @(posedge clk) 				    x <= 32'sd2 * $signed(65536); y <= 32'sd4 * $signed(65536);
    #10 @(posedge clk) 				    x <= 32'sd10 * $signed(65536); y <= 32'sd15 * $signed(65536);
    #10 @(posedge clk) 				    x <= -32'sd10 * $signed(65536); y <= -32'sd15 * $signed(65536);
    #10 @(posedge clk) 				    x <= -32'sd10 * $signed(65536); y <= 32'sd15 * $signed(65536);
    #10 @(posedge clk)pre_vaild <= 1'b0;
    
    #200@(posedge clk)
        pre_vaild <= 1'b1; 
        x <= -32'sd2 * $signed(65536);
        y <= -32'sd2 * $signed(65536);
        
    #10 @(posedge clk) 				    x <= 32'sd2 * $signed(65536); y <= -32'sd4 * $signed(65536);
    #10 @(posedge clk) 				    x <= 32'sd100 * $signed(65536); y <= 32'sd100 * $signed(65536);
    #10 @(posedge clk) 				    x <= 32'sd10 * $signed(65536); y <= 32'sd0 * $signed(65536);
    #10 @(posedge clk) 				    x <= 32'sd0 * $signed(65536); y <= 32'sd10 * $signed(65536);
	#10 @(posedge clk)pre_vaild <= 1'b0;
	#100000 $stop;	
end

always #(PERIOD/2) clk = ~clk;

cordic_amplitude_angle
#(    
    .PIPELINE(16)                        //pipe数，最大支持16
)cordic_amplitude_angle
(
    .clk         (clk  ),
    .rst_n       (rst_n),
                 
    .x           (x        ),     
    .y           (y        ),
    .pre_vaild   (pre_vaild),
                 
    .amplitude   (amplitude ), 
    .angle       (angle     ),
    .post_vaild  (post_vaild)

);//延迟PIPELINE+3拍

endmodule

