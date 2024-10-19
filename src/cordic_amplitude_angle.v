module  cordic_amplitude_angle
#(    
    parameter PIPELINE  = 16                        //pipe数，最大支持16
)
(
    input                               clk         ,
    input                               rst_n       ,
    
    input       signed  [31:0]          x           ,   //16位小数位       
    input       signed  [31:0]          y           ,
    input                               pre_vaild   ,

    output  reg signed  [31:0]          amplitude   ,  //幅度
    output  reg signed  [31:0]          angle       ,  //角度
    output  reg                         post_vaild

);//延迟PIPELINE+4拍

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

reg signed  [31:0]  x_map;
reg signed  [31:0]  y_map;
reg         [1:0]   site ;

always@(posedge clk or negedge rst_n)begin 
    if(!rst_n)begin
        x_map   <=  0;
        y_map   <=  0;
        site    <=  2'd1;
    end
    else    if(x >= 0)begin
        x_map   <=  x;  
        y_map   <=  y;
        site    <=  2'd1;
    end
    else    if(x < 0 && y >= 0)begin
        x_map   <=  -x;  
        y_map   <=  y;
        site    <=  2'd2;
    end
    else    begin
        x_map   <=  -x;  
        y_map   <=  y;
        site    <=  2'd3;
    end
end

reg signed 	[31:0] 		currentX[PIPELINE:0];
reg signed 	[31:0] 		currentY[PIPELINE:0];
reg signed 	[31:0] 		currentZ[PIPELINE:0];

always@(posedge clk or negedge rst_n)begin
   if(!rst_n)begin
       currentX[0]    <=  32'sd0;
       currentY[0]    <=  32'sd0;
       currentZ[0]    <=  32'sd0;
   end
   else    begin
       currentX[0]    <=   x_map;
       currentY[0]    <=   y_map;
       currentZ[0]    <=   32'sd0;
   end
end

genvar i;
generate
    for(i = 1;i < PIPELINE + 1;i = i + 1)begin:cal_xyz
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                currentX[i]    <=  32'sd0;
                currentY[i]    <=  32'sd0;
                currentZ[i]    <=  32'sd0;
            end
            else    if(currentY[i-1][31])begin
                currentX[i]    <=  currentX[i-1] - (currentY[i-1] >>> (i-1));
                currentY[i]    <=  currentY[i-1] + (currentX[i-1] >>> (i-1));
                currentZ[i]    <=  currentZ[i-1] - angle_array[i-1];
            end
            else    begin
                currentX[i]    <=  currentX[i-1] + (currentY[i-1] >>> (i-1));
                currentY[i]    <=  currentY[i-1] - (currentX[i-1] >>> (i-1));
                currentZ[i]    <=  currentZ[i-1] + angle_array[i-1];
            end
        end 
    end
endgenerate

reg     [PIPELINE+2:0]      vaild_r;
reg     [2*PIPELINE+3:0]    site_r;

always@(posedge clk )begin
    vaild_r <=  {vaild_r[PIPELINE+1:0],pre_vaild};
    site_r  <=  {site_r[2*PIPELINE+1:0],site};   
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        post_vaild  <=  0;
    else
        post_vaild  <=  vaild_r[PIPELINE+2];
end

reg signed [47:0]  K_mult_currentX;
reg signed [31:0]  currentZ_r;

always@(posedge clk)begin
    K_mult_currentX <=  K*currentX[PIPELINE];
    currentZ_r      <=  currentZ[PIPELINE];
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        amplitude <=  0;
        angle     <=  0;
    end
    else    if(~vaild_r[PIPELINE+2])begin
        amplitude <=  0;
        angle     <=  0;
    end
    else    begin
        case(site_r[2*PIPELINE+3:2*PIPELINE+2])
            2'd1:begin
                amplitude <=  K_mult_currentX >>> 16;
                angle     <=  currentZ_r;
            end
            2'd2:begin
                amplitude <=  K_mult_currentX >>> 16;
                angle     <=  32'sd11796480 - currentZ_r;
            end
            2'd3:begin
                amplitude <=  K_mult_currentX >>> 16;
                angle     <=  -32'sd11796480 - currentZ_r;
            end      
            default:begin
                amplitude <=  K_mult_currentX >>> 16;
                angle     <=  currentZ_r;
            end
        endcase  
    end
end



endmodule