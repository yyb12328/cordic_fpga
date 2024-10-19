module  cordic_arcsin_arccos
#(    
    parameter PIPELINE  = 16                        //pipe数，最大支持16
)
(
    input                               clk         ,
    input                               rst_n       ,
    
    input       signed  [31:0]          iData       ,   //16位小数位,-1~1  
    input                               pre_vaild   ,

    output  reg signed  [31:0]          arcsin      , 
    output  reg signed  [31:0]          arccos      ,
    output  reg                         post_vaild

);//延迟PIPELINE+2拍

wire signed [31:0]  angle_array[15:0];

assign angle_array[0]  = 32'sd2949120;    //45度*2^16
assign angle_array[1]  = 32'sd1740992;    //26.5651度*2^16
assign angle_array[2]  = 32'sd919872;     //14.0362度*2^16
assign angle_array[3]  = 32'sd466944;     //7.1250度*2^16
assign angle_array[4]  = 32'sd234368;     //3.5763度*2^16
assign angle_array[5]  = 32'sd117312;     //1.7899度*2^16
assign angle_array[6]  = 32'sd58688;      //0.8952度*2^16
assign angle_array[7]  = 32'sd29312;      //0.4476度*2^16
assign angle_array[8]  = 32'sd14656;      //0.2238度*2^16
assign angle_array[9]  = 32'sd7360;       //0.1119度*2^16
assign angle_array[10] = 32'sd3648;       //0.0560度*2^16
assign angle_array[11] = 32'sd1856;	     //0.0280度*2^16
assign angle_array[12] = 32'sd896;        //0.0140度*2^16
assign angle_array[13] = 32'sd448;        //0.0070度*2^16
assign angle_array[14] = 32'sd256;        //0.0035度*2^16
assign angle_array[15] = 32'sd128;        //0.0018度*2^16

localparam K        = 32'sh09b74;	  //0.607253*2^16 

reg signed 	[31:0] 		currentX[PIPELINE:0];
reg signed 	[31:0] 		currentY[PIPELINE:0];
reg signed 	[31:0] 		currentZ[PIPELINE:0];
reg signed 	[31:0] 	 	iDatar[PIPELINE:0];

always@(posedge clk or negedge rst_n)begin
   if(!rst_n)begin
       currentX[0]  <=  32'sd0;
       currentY[0]  <=  32'sd0;
       currentZ[0]  <=  32'sd0;       
       iDatar[0]    <=  32'sd0;
   end
   else    begin
       currentX[0]  <=  K;
       currentY[0]  <=  32'sd0;
       currentZ[0]  <=  32'sd0;      
       iDatar[0]    <=  iData;
   end
end

genvar i;
generate
    for(i = 1;i < PIPELINE + 1;i = i + 1)begin:cal_xyz
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                currentX[i]   <=  32'sd0;
                currentY[i]   <=  32'sd0;
                currentZ[i]   <=  32'sd0;
                iDatar[i]     <=  32'sd0; 

            end
            else    if(currentY[i-1] < iDatar[i-1])begin
                currentX[i]   <=  currentX[i-1] - (currentY[i-1] >>> (i-1));
                currentY[i]   <=  currentY[i-1] + (currentX[i-1] >>> (i-1));
                currentZ[i]   <=  currentZ[i-1] - angle_array[i-1]; 
                iDatar[i]     <=  iDatar[i-1];           
            end
            else    begin
                currentX[i]   <=  currentX[i-1] + (currentY[i-1] >>> (i-1));
                currentY[i]   <=  currentY[i-1] - (currentX[i-1] >>> (i-1));
                currentZ[i]   <=  currentZ[i-1] + angle_array[i-1];
                iDatar[i]     <=  iDatar[i-1];
            end
        end 
    end
endgenerate

reg     [PIPELINE:0]        vaild_r;

always@(posedge clk )begin
    vaild_r <=  {vaild_r[PIPELINE-1:0],pre_vaild};
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        post_vaild  <=  0;
    else
        post_vaild  <=  vaild_r[PIPELINE];
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        arcsin  <=  0;
        arccos  <=  0;
    end
    else    if(~vaild_r[PIPELINE])begin
        arcsin  <=  0;
        arccos  <=  0;
    end
    else    begin
        arcsin  <=  -currentZ[PIPELINE];
        arccos  <=  32'sd5898240 + currentZ[PIPELINE];
    end
end

endmodule