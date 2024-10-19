module  cordic_exp_plus
#(    
    parameter WII       = 16,
    parameter WOI       = 16,
    parameter WOF       = 16,                       //输出的浮点位数，目前只能16
    parameter PIPELINE  = 16                        //pipe数，最大支持16
)
(
    input                               clk         ,
    input                               rst_n       ,
    
    input       signed  [WII+15:0]      iData       ,   //16位小数位    
    input                               pre_vaild   ,

    output  reg signed  [WOI+WOF-1:0]   exp         , 
    output  reg                         post_vaild

);//延迟PIPELINE+6拍

wire signed [31:0]  alpha_array[15:0];

assign alpha_array[0]   =   32'sd35999; 
assign alpha_array[1]   =   32'sd16739; 
assign alpha_array[2]   =   32'sd8235;
assign alpha_array[3]   =   32'sd4101;
assign alpha_array[4]   =   32'sd2049;
assign alpha_array[5]   =   32'sd1024;
assign alpha_array[6]   =   32'sd512;
assign alpha_array[7]   =   32'sd256;
assign alpha_array[8]   =   32'sd128;
assign alpha_array[9]   =   32'sd64;
assign alpha_array[10]  =   32'sd32;
assign alpha_array[11]  =   32'sd16;
assign alpha_array[12]  =   32'sd8;
assign alpha_array[13]  =   32'sd4;
assign alpha_array[14]  =   32'sd2;
assign alpha_array[15]  =   32'sd1;

localparam K = 32'sd79137;      //1.207534*65536
localparam IN2 = 32'sd45426;    //In2 * 65536

/**********************************
q = alpha/IN2 
r = alpha - (q*IN2)
t =  exp(r)
exp = t*2^q
***********************************/
//alpha/45426 = alpha * 2^28/45426/2^28= alpha * 5909 >>> 28

wire    signed [WII+15:0]   alpha_abs;
wire                        sign;
reg     [PIPELINE+4:0]      sign_r;

reg     signed [WII+15:0]   alpha_r1;
reg     signed [WII+15:0]   alpha_r2;
reg            [2:0]        vaild_r;

reg     signed [WII+15+16:0]mult_alpha;  //alpha*16'sd5909 >>> 28
wire    signed [WII+3:0]    q;
reg     signed [WII+15:0]   mult_q;
reg     signed [31:0]       r;
wire    signed [31:0]       r_abs;

assign  alpha_abs = iData[WII+15] ? (~iData + 1) : iData;
assign  sign =  iData[WII+15];
always@(posedge clk)    sign_r  <=  {sign_r[PIPELINE+3:0],sign};     

always@(posedge clk)begin
    alpha_r1    <=  alpha_abs;
    alpha_r2    <=  alpha_r1;
end

always@(posedge clk)    vaild_r <=  {vaild_r[1:0],pre_vaild};

always@(posedge clk)
    if(pre_vaild)
        mult_alpha  <=  alpha_abs * 16'sd5909;
    else    
        mult_alpha  <=  0;

assign  q   =  (mult_alpha >>> 28) + 32'sd1;    

always@(posedge clk)
    if(vaild_r[0])
        mult_q  <=  q * IN2;
    else    
        mult_q  <=  0;
                          
always@(posedge clk)    
    if(vaild_r[1])
        r   <=  alpha_r2 - mult_q;
    else
        r   <=  0;

assign  r_abs = sign_r[2] ? (~r+1) : r;

wire signed [31:0]      exp_t;  
wire                    vaild_r2;
wire signed [WII+3:0]   q_r;

cordic_exp
#(    
    .PIPELINE(PIPELINE)                        //pipe数，最大支持16
)cordic_exp
(
    .clk         (clk  ),
    .rst_n       (rst_n),
                 
    .iData       (r_abs),   //16位小数位,-1.13~1.13    
    .pre_vaild   (vaild_r[2]),
                 
    .exp         (exp_t), 
    .post_vaild  (vaild_r2)

);//延迟PIPELINE+2拍

data_delay  
#(
    .DATA_WIDTH(WII+4),
    .DATA_DELAY(PIPELINE+4)
)data_delay
(
    .I_video_clk(clk  ),
    .I_rst_n    (rst_n),   
    .I_data     (q),
                
    .O_data     (q_r)
);


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        exp <=  0;
    end
    else    begin
        exp <=  sign_r[PIPELINE+4] ? exp_t >>> q_r : exp_t <<< q_r;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        post_vaild  <=  0;
    else
        post_vaild  <=  vaild_r2;  
end


endmodule