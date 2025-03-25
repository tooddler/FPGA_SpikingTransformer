/*
    - Controller / Router - :
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module simple_eyeriss_Controller (
    input                                            s_clk                     ,
    input                                            s_rst                     ,

    input                                            SpikingEncoder_out_done   ,
    input                                            SPS_part_done             ,
    output wire                                      o_fetch_code_done         ,
    output reg                                       o_sps_DataGetReady        ,
    // -- Code 
    output reg                                       o_code_valid              ,
    output wire [15:0]                               o_conv_in_ch              ,
    output wire [15:0]                               o_conv_out_ch             ,
    output wire [15:0]                               o_conv_img_size           ,
    output wire [15:0]                               o_conv_lif_thrd           ,
    output wire [15:0]                               o_conv_bias_scale         ,
    output wire                                      o_conv_or_maxpool         ,
    // -- Tmp-Bram00 interface
    output wire                                      TmpRam00_wea              , // wr
    output wire  [12 : 0]                            TmpRam00_addra            ,   
    output wire  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]    TmpRam00_dina             ,
    output wire  [12 : 0]                            TmpRam00_addrb            , // rd
    input        [`IMG_WIDTH*`TIME_STEPS - 1 : 0]    TmpRam00_doutb            ,
    // -- Tmp-Bram01 interface
    output wire                                      TmpRam01_wea              , // wr
    output wire  [12 : 0]                            TmpRam01_addra            ,   
    output wire  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]    TmpRam01_dina             ,
    output wire  [12 : 0]                            TmpRam01_addrb            , // rd
    input        [`IMG_WIDTH*`TIME_STEPS - 1 : 0]    TmpRam01_doutb            ,
    // -- Eyeriss Array interface
    output reg                                       ifmap_spikes_valid=0      , // send to Array
    output wire  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]    ifmap_spikes              , 
    output reg                                       ifmap_spikes_done=0       ,
    input                                            ifmap_spikes_ready        , 

    input                                            Array_out_valid           , // get from Array
    input        [`IMG_WIDTH*`TIME_STEPS - 1 : 0]    Array_out_spikes          , 
    input                                            Array_out_done            ,
    output reg                                       Array_out_ready=0
);

localparam  S_IDLE              =   0  ,
            S_FETCH_CODE        =   1  , 
            S_CHECK_RAM_SWITCH  =   2  ,
            S_MAXPOOL           =   3  ,
            S_SEND_DATA         =   4  ,
            S_DATA_FETCH        =   5  ,
            S_DONE              =   6  ;

wire                                            code_valid                  ;
wire [15:0]                                     Conv_in_ch                  ;
wire [15:0]                                     Conv_out_ch                 ;
wire [15:0]                                     Conv_img_size               ;
wire [15:0]                                     Conv_lif_thrd               ;
wire [15:0]                                     Conv_bias_scale             ;
wire                                            Conv_or_Maxpool             ;

wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]           w_TmpRam_rd_data            ; // RAM RD PORT
wire                                            w_fetch_code_done           ;

reg  [2:0]                                      s_curr_state                ;
reg  [2:0]                                      s_next_state                ;
reg                                             code_ready=0                ; // req signal

reg  [15:0]                                     r_conv_lif_thrd             ;
reg  [15:0]                                     r_conv_in_ch                ;
reg  [15:0]                                     r_conv_out_ch               ;
reg  [15:0]                                     r_conv_img_size             ;
reg  [15:0]                                     r_conv_bias_scale           ;
reg                                             r_conv_or_maxpool           ;

reg                                             r_TmpRam_switch             ; // 1: RAM00  ;  0: RAM01
reg  [9:0]                                      r_cycle_cnt                 ;
reg                                             r_padding_flag              ;
reg                                             r_padding_flag_d0           ;
reg                                             r_padding_flag_d1           ;

reg  [12:0]                                     r_TmpRam_rd_addr            ; // RAM RD PORT
reg  [2:0]                                      r_TmpRam_rd_cnt             ;
reg  [12:0]                                     r_addr_ptr                  ;
reg  [12:0]                                     r_addr_ptr_register         ;
reg  [9:0]                                      r_addr_ptr_register_cnt     ;

reg  [6:0]                                      r_addr_ptr_cnt              ;
reg  [12:0]                                     r_baseaddr                  ;
reg  [12:0]                                     r_baseaddr_copy             ;
reg  [5:0]                                      r_img_row_cnt               ;

reg                                             r_TmpRam_wr_wea=0           ; // RAM WR PORT
reg  [12:0]                                     r_TmpRam_wr_addra           ;
reg  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]           r_TmpRam_wr_data            ;

reg                                             r_once_cycle_done=0         ;
reg                                             r_1cycle_done=0             ;
reg                                             r_conv_or_maxpool_d0=0      ;

assign o_conv_in_ch      =  r_conv_in_ch      ;
assign o_conv_out_ch     =  r_conv_out_ch     ;
assign o_conv_img_size   =  r_conv_img_size   ;
assign o_conv_or_maxpool =  r_conv_or_maxpool ;
assign o_conv_lif_thrd   =  r_conv_lif_thrd   ;
assign o_conv_bias_scale =  r_conv_bias_scale ;

assign o_fetch_code_done = w_fetch_code_done  ;

// --------------- Tmp-RAM arbtier --------------- \\ 
// -- wr --
assign TmpRam00_wea     = r_TmpRam_switch ? 'd0 : r_TmpRam_wr_wea   ;
assign TmpRam00_addra   = r_TmpRam_switch ? 'd0 : r_TmpRam_wr_addra ;
assign TmpRam00_dina    = r_TmpRam_switch ? 'd0 : r_TmpRam_wr_data  ;

assign TmpRam01_wea     = r_TmpRam_switch ? r_TmpRam_wr_wea   : 'd0 ;
assign TmpRam01_addra   = r_TmpRam_switch ? r_TmpRam_wr_addra : 'd0 ;
assign TmpRam01_dina    = r_TmpRam_switch ? r_TmpRam_wr_data  : 'd0 ;

// -- rd --
assign TmpRam00_addrb   = r_TmpRam_switch                           ? r_TmpRam_rd_addr   : 'd0                 ; 
assign TmpRam01_addrb   = r_TmpRam_switch                           ? 'd0                : r_TmpRam_rd_addr    ; 
assign w_TmpRam_rd_data = r_TmpRam_switch                           ? TmpRam00_doutb     : TmpRam01_doutb      ;
assign ifmap_spikes     = (r_padding_flag_d1 && ~r_conv_or_maxpool) ? 'd0                : w_TmpRam_rd_data    ;

// JUST FOR DEBUG
// assign ifmap_spikes = (r_padding_flag_d1 && ~r_conv_or_maxpool) ? 'd0 : {(`IMG_WIDTH*`TIME_STEPS){1'b1}};

// --------------- state --------------- \\
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        s_curr_state <= S_IDLE;
    else
        s_curr_state <= s_next_state;
end

// --------------- sequential logic --------------- \\ 
// code_ready
always@(posedge s_clk) begin
    if (code_ready && code_valid)
        code_ready <= 1'b0;
    else if (s_curr_state == S_FETCH_CODE)
        code_ready <= 1'b1;
    else
        code_ready <= 1'b0;
end

// o_code_valid
always@(posedge s_clk) begin
    if (code_ready && code_valid)
        o_code_valid <= 1'b1;
    else
        o_code_valid <= 1'b0;
end

// r_conv
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_conv_in_ch      <= 'd0;
        r_conv_out_ch     <= 'd0;
        r_conv_img_size   <= 'd0;
        r_conv_lif_thrd   <= 'd0;
        r_conv_bias_scale <= 'd0;
        r_conv_or_maxpool <= 1'b0;
    end
    else if (code_ready && code_valid) begin
        r_conv_in_ch      <= Conv_in_ch     ;
        r_conv_out_ch     <= Conv_out_ch    ;
        r_conv_img_size   <= Conv_img_size  ;
        r_conv_lif_thrd   <= Conv_lif_thrd  ;
        r_conv_bias_scale <= Conv_bias_scale;
        r_conv_or_maxpool <= Conv_or_Maxpool;
    end
end

// data ready signal  ->  o_sps_DataGetReady
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || SPS_part_done)
        o_sps_DataGetReady <= 1'b0;
    else if (s_curr_state == S_DONE && w_fetch_code_done)
        o_sps_DataGetReady <= 1'b1;
end

// r_TmpRam_switch
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_TmpRam_switch <= 1'b0;
    else if (s_curr_state == S_CHECK_RAM_SWITCH)
        r_TmpRam_switch <= ~r_TmpRam_switch;
end

// r_once_cycle_done
always@(posedge s_clk) begin
    if ((r_baseaddr_copy >= r_conv_img_size - 2) && (r_addr_ptr_register_cnt == (r_conv_in_ch >> $clog2(`ERS_PE_NUM))) - 1)
        r_once_cycle_done <= 1'b1;
    else
        r_once_cycle_done <= 1'b0;
end

// r_padding_flag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_padding_flag <= 1'b0;
    else if (ifmap_spikes_valid && ifmap_spikes_ready && r_TmpRam_rd_cnt == 'd4 && r_baseaddr_copy == 'd0)
        r_padding_flag <= 1'b1;
    else if (ifmap_spikes_valid && ifmap_spikes_ready && r_TmpRam_rd_cnt == 'd4)
        r_padding_flag <= 1'b0;
    else if (ifmap_spikes_valid && ifmap_spikes_ready && r_baseaddr_copy > r_conv_img_size - 6 && r_img_row_cnt >= r_conv_img_size - 3)
        r_padding_flag <= 1'b1;
    else if (ifmap_spikes_ready && ~ifmap_spikes_valid && r_baseaddr_copy == 'd0)
        r_padding_flag <= 1'b1;
    else
        r_padding_flag <= 1'b0;
end

// r_padding_flag_d0
always@(posedge s_clk) begin
    r_padding_flag_d0 <= r_padding_flag     ;
    r_padding_flag_d1 <= r_padding_flag_d0  ;
end

// r_img_row_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_img_row_cnt <='d0;
    else if ((ifmap_spikes_ready && ifmap_spikes_valid && r_TmpRam_rd_cnt == 'd4) || r_once_cycle_done || (~r_conv_or_maxpool && r_conv_or_maxpool_d0))
        r_img_row_cnt <= r_baseaddr_copy;
    else if (ifmap_spikes_ready && ifmap_spikes_valid)
        r_img_row_cnt <= r_img_row_cnt + 1'b1;
end

// ifmap_spikes_valid
always@(posedge s_clk) begin
    if (ifmap_spikes_ready && (s_curr_state == S_SEND_DATA || s_curr_state == S_MAXPOOL))
        ifmap_spikes_valid <= 1'b1;
    else 
        ifmap_spikes_valid <= 1'b0;
end

// r_TmpRam_rd_addr r_TmpRam_rd_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_1cycle_done) begin
        r_TmpRam_rd_addr <= 'd0;
        r_TmpRam_rd_cnt  <= 'd0;
    end
    else if (ifmap_spikes_valid && ifmap_spikes_ready && r_conv_or_maxpool) begin
        r_TmpRam_rd_addr <= r_TmpRam_rd_addr + 1'b1;
        r_TmpRam_rd_cnt  <= 'd0;
    end
    else if ((ifmap_spikes_valid && ifmap_spikes_ready && r_TmpRam_rd_cnt == 'd4) || r_once_cycle_done) begin
        r_TmpRam_rd_addr <= r_addr_ptr;
        r_TmpRam_rd_cnt  <= 'd0;
    end
    else if (ifmap_spikes_valid && ifmap_spikes_ready && r_padding_flag) begin
        r_TmpRam_rd_addr <= r_TmpRam_rd_addr;
        r_TmpRam_rd_cnt  <= r_TmpRam_rd_cnt + 1'b1;
    end
    else if (ifmap_spikes_valid && ifmap_spikes_ready) begin
        r_TmpRam_rd_addr <= r_TmpRam_rd_addr + 1'b1;
        r_TmpRam_rd_cnt  <= r_TmpRam_rd_cnt + 1'b1;
    end
end

// r_addr_ptr_register r_addr_ptr_register_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_addr_ptr_register <= 'd0;
        r_addr_ptr_register_cnt <= 'd0;
    end
    else if (r_addr_ptr_register_cnt == (r_conv_in_ch >> $clog2(`ERS_PE_NUM))) begin
        r_addr_ptr_register <= 'd0;
        r_addr_ptr_register_cnt <= 'd0; 
    end
    else if (r_baseaddr_copy >= r_conv_img_size - 2) begin
        r_addr_ptr_register <= r_addr_ptr_register + ((r_conv_img_size - 2) << $clog2(`ERS_PE_NUM));
        r_addr_ptr_register_cnt <= r_addr_ptr_register_cnt + 1'b1;
    end
end

// r_addr_ptr r_addr_ptr_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_1cycle_done) begin
        r_addr_ptr <= 'd0;
        r_addr_ptr_cnt <= 'd0;
    end
    else if (r_once_cycle_done) begin
        r_addr_ptr <= r_baseaddr;
        r_addr_ptr_cnt <= 'd0;
    end
    else if (r_baseaddr_copy >= r_conv_img_size - 2) begin
        r_addr_ptr <= r_addr_ptr_register + ((r_conv_img_size - 2) << $clog2(`ERS_PE_NUM));
        r_addr_ptr_cnt <= 'd0;
    end
    else if (ifmap_spikes_valid && ifmap_spikes_ready && r_TmpRam_rd_cnt == 'd3 && r_addr_ptr_cnt == `ERS_PE_NUM - 1'b1) begin
        r_addr_ptr <= (r_baseaddr_copy == 'd0) ? r_baseaddr + 'd2 : r_baseaddr + 'd3;
        r_addr_ptr_cnt <= 'd0;
    end
    else if (ifmap_spikes_valid && ifmap_spikes_ready && r_TmpRam_rd_cnt == 'd3) begin
        r_addr_ptr <= r_addr_ptr + r_conv_img_size - 2;
        r_addr_ptr_cnt <= r_addr_ptr_cnt + 1'b1;
    end
end

// r_baseaddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_baseaddr <= 'd0;
    else if (r_addr_ptr_register_cnt == (r_conv_in_ch >> $clog2(`ERS_PE_NUM)))
        r_baseaddr <= 'd0;
    else if (r_baseaddr_copy >= r_conv_img_size - 2)
        r_baseaddr <= r_addr_ptr_register + ((r_conv_img_size - 2) << $clog2(`ERS_PE_NUM));
    else if (ifmap_spikes_valid && ifmap_spikes_ready && r_TmpRam_rd_cnt == 'd3 && r_addr_ptr_cnt == `ERS_PE_NUM - 1'b1)
        r_baseaddr <= (r_baseaddr_copy == 'd0) ? r_baseaddr + 'd2 : r_baseaddr + 'd3;
end

// r_baseaddr_copy
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_baseaddr_copy <= 'd0;
    else if (r_baseaddr_copy >= r_conv_img_size - 2)
        r_baseaddr_copy <= 'd0;
    else if (ifmap_spikes_valid && ifmap_spikes_ready && r_TmpRam_rd_cnt == 'd3 && r_addr_ptr_cnt == `ERS_PE_NUM - 1'b1)
        r_baseaddr_copy <= (r_baseaddr_copy == 'd0) ? r_baseaddr_copy + 'd2 : r_baseaddr_copy + 'd3;
end

// r_cycle_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_cycle_cnt <= 'd0;
    else if (r_cycle_cnt == r_conv_out_ch && Array_out_done)
        r_cycle_cnt <= 'd0;
    else if (r_addr_ptr_register_cnt == (r_conv_in_ch >> $clog2(`ERS_PE_NUM)) && s_curr_state == S_SEND_DATA)
        r_cycle_cnt <= r_cycle_cnt + 1'b1;
end

// r_1cycle_done
always@(posedge s_clk) begin
    r_conv_or_maxpool_d0 <= r_conv_or_maxpool;

    if (r_addr_ptr_register_cnt == (r_conv_in_ch >> $clog2(`ERS_PE_NUM)) || (~r_conv_or_maxpool && r_conv_or_maxpool_d0))
        r_1cycle_done <= 1'b1;
    else 
        r_1cycle_done <= 1'b0;
end

// Array_out_ready
always@(posedge s_clk) begin
    if (s_curr_state == S_DATA_FETCH || s_curr_state == S_MAXPOOL)
        Array_out_ready <= 1'b1;
    else 
        Array_out_ready <= 1'b0;
end

// r_TmpRam_wr_wea
always@(posedge s_clk) begin
    if (Array_out_ready && Array_out_valid)
        r_TmpRam_wr_wea <= 1'b1;
    else 
        r_TmpRam_wr_wea <= 1'b0;
end

// r_TmpRam_wr_addra
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_TmpRam_wr_addra <= 'd0;
    else if (s_curr_state == S_CHECK_RAM_SWITCH)
        r_TmpRam_wr_addra <= 'd0;
    else if (r_TmpRam_wr_wea)
        r_TmpRam_wr_addra <= r_TmpRam_wr_addra + 1'b1;
end

// r_TmpRam_wr_data 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_TmpRam_wr_data <= 'd0;
    else if (Array_out_ready && Array_out_valid)
        r_TmpRam_wr_data <= Array_out_spikes;
end

// ifmap_spikes_done
always@(posedge s_clk) begin
    if (r_cycle_cnt == r_conv_out_ch - 1 && (r_addr_ptr_register_cnt == (r_conv_in_ch >> $clog2(`ERS_PE_NUM))))
        ifmap_spikes_done <= 1'b1;
    else 
        ifmap_spikes_done <= 1'b0;
end

// --------------- instantiation --------------- \\ 
code_fetch u_code_fetch(
    .s_clk            ( s_clk             ),
    .s_rst            ( s_rst             ),

    .SPS_part_done    ( SPS_part_done     ),
    .code_valid       ( code_valid        ),
    .code_ready       ( code_ready        ), 

    .o_fetch_done     ( w_fetch_code_done ),
    .Conv_lif_thrd    ( Conv_lif_thrd     ),
    .Conv_bias_scale  ( Conv_bias_scale   ),
    .Conv_or_Maxpool  ( Conv_or_Maxpool   ),
    .Conv_in_ch       ( Conv_in_ch        ),
    .Conv_out_ch      ( Conv_out_ch       ),
    .Conv_img_size    ( Conv_img_size     )
);

// --------------- Finite-State-Machine --------------- \\
always@(*) begin

    case(s_curr_state)
        S_IDLE:              s_next_state = SpikingEncoder_out_done ? S_FETCH_CODE : S_IDLE;
        S_FETCH_CODE:        s_next_state = (code_valid && code_ready) ? S_CHECK_RAM_SWITCH : S_FETCH_CODE;
        S_CHECK_RAM_SWITCH:  s_next_state = r_conv_or_maxpool ? S_MAXPOOL : S_SEND_DATA;
        S_MAXPOOL:           s_next_state = Array_out_done ? S_FETCH_CODE : S_MAXPOOL;
        S_SEND_DATA:         s_next_state = (r_addr_ptr_register_cnt == (r_conv_in_ch >> $clog2(`ERS_PE_NUM))) ? S_DATA_FETCH : S_SEND_DATA;
        S_DATA_FETCH:        s_next_state = Array_out_done ? ((r_cycle_cnt == r_conv_out_ch) ? S_DONE : S_SEND_DATA) : S_DATA_FETCH; 
        S_DONE:              s_next_state = w_fetch_code_done ? (SPS_part_done ? S_IDLE : S_DONE) : S_FETCH_CODE;   
        default:             s_next_state = S_IDLE; 
    endcase

end

endmodule // simple_eyeriss_Controller
