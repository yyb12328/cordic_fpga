module  cordic_sinh_cosh_plus
#(    
    parameter WII       = 16,                       //输入数据整数位数        
    parameter WOI       = 16,                       //输出数据整数位数   
    parameter PIPELINE  = 16                        //pipe数，最大支持16
)
(
    input                               clk         ,
    input                               rst_n       ,
    
    input       signed  [WII+15:0]      alpha       ,   //16位小数位    
    input                               pre_vaild   ,

    output  reg signed  [WOI+15:0]      sinh        , 
    output  reg signed  [WOI+15:0]      cosh        ,
    output  reg                         post_vaild

);//延迟PIPELINE+7拍

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
x = cosh(r)
y = sinh(r)
t =  (x-y)*2^(-2*q)
cosh = (x+y+t)*2^(q-1)
sinh = (x+y-t)*2^(q-1)
***********************************/
//alpha/45426 = alpha * 2^28/45426/2^28= alpha * 5909 >>> 28

wire    signed [WII+15:0]   alpha_abs;
wire                        sign;
reg     [PIPELINE+5:0]      sign_r;

reg     signed [WII+15:0]   alpha_r1;
reg     signed [WII+15:0]   alpha_r2;
reg            [2:0]        vaild_r;

reg     signed [WII+15+16:0]mult_alpha;  //alpha*16'sd5909 >>> 28
wire    signed [WII+3:0]    q;
reg     signed [WII+15:0]   mult_q;
reg     signed [31:0]       r;

assign  alpha_abs = alpha[WII+15] ? (~alpha + 1) : alpha;
assign  sign =  alpha[WII+15];
always@(posedge clk)    sign_r  <=  {sign_r[PIPELINE+4:0],sign};     

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

wire signed [31:0]      sinh_t;  
wire signed [31:0]      cosh_t;
wire                    vaild_r2;
reg                     vaild_r3;
wire signed [WII+3:0]   q_r;
reg  signed [WII+3:0]   q_r2;

cordic_sinh_cosh
#(    
    .PIPELINE(PIPELINE)                        //pipe数，最大支持16
)cordic_sinh_cosh
(
    .clk         (clk  ),
    .rst_n       (rst_n),
                 
    .alpha       (r),   //16位小数位,-1.13~1.13    
    .pre_vaild   (vaild_r[2]),
                 
    .sinh        (sinh_t), 
    .cosh        (cosh_t),
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

always@(posedge clk) q_r2 <=    q_r;
always@(posedge clk) vaild_r3 <= vaild_r2;   

reg     signed [31:0]       t;
reg     signed [31:0]       sinh_t_r;  
reg     signed [31:0]       cosh_t_r;
wire    signed [WOI+15:0]   sinh_abs; 
wire    signed [WOI+15:0]   cosh_abs;

always@(posedge clk)    t   <=  (cosh_t - sinh_t) >>> (q_r <<< 1);

always@(posedge clk)begin
    sinh_t_r    <=  sinh_t;
    cosh_t_r    <=  cosh_t;
end

assign  sinh_abs = q_r2 ? (sinh_t_r + cosh_t_r - t) <<< (q_r2 - 1) : (sinh_t_r + cosh_t_r - t) >>> 1;
assign  cosh_abs = q_r2 ? (sinh_t_r + cosh_t_r + t) <<< (q_r2 - 1) : (sinh_t_r + cosh_t_r + t) >>> 1;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        sinh    <=  0;
        cosh    <=  0;
    end
    else    begin
        sinh    <=  sign_r[PIPELINE+5] ? (~sinh_abs+1):sinh_abs;
        cosh    <=  cosh_abs;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        post_vaild  <=  0;
    else
        post_vaild  <=  vaild_r3;  
end


endmodule