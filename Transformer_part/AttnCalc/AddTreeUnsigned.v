/*
    -- add_tree --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    PS      : Unsigned mode
*/

module AddTreeUnsigned #(
    parameter INPUTS_NUM     = 27                       ,
    parameter IDATA_WIDTH    = 8                        , 
    
    parameter STAGES_NUM     = $clog2(INPUTS_NUM)       ,
    parameter INPUTS_NUM_INT = 2 ** STAGES_NUM          ,
    parameter ODATA_WIDTH    = IDATA_WIDTH + STAGES_NUM
)(
    input                                       sclk     ,       
    input                                       s_rst_n  ,
    // - <INPUTS_NUM> input signals with a bit width of <IDATA_WIDTH> added together -
    input  [INPUTS_NUM *IDATA_WIDTH -1 : 0]     idata    ,       
    // - module_out -
    output wire   [ODATA_WIDTH -1 : 0]          data_out 
);

// ----- reg -----
// - restore all of tree nodes data - 
reg  [ODATA_WIDTH-1:0] data [STAGES_NUM:0][INPUTS_NUM_INT-1:0]  ;

// ---------------------------- generate -------------------------
genvar stage, adder;
generate 
    for(stage = 0; stage <= STAGES_NUM; stage=stage+1) begin: stage_gen
        localparam ST_OUT_NUM = INPUTS_NUM_INT >> stage ;
        localparam ST_WIDTH   = IDATA_WIDTH + stage     ;
        if( stage == 0 ) begin  // stege 0 is actually module inputs
            for(adder = 0; adder < ST_OUT_NUM; adder=adder+1) begin: inputs_gen
                always@(*)begin
                    if (s_rst_n == 1'b0)
                        data[stage][adder][ODATA_WIDTH-1:0] = 'd0;
                    else if ( adder < INPUTS_NUM ) begin
                        data[stage][adder][ST_WIDTH-1:0] = idata[IDATA_WIDTH*adder + IDATA_WIDTH - 1 : IDATA_WIDTH*adder];
                        data[stage][adder][ODATA_WIDTH-1:ST_WIDTH] = 'd0;
                    end
                end
            end
        end
        else begin   // all other stages hold adders outputs
            for(adder = 0; adder < ST_OUT_NUM; adder=adder+1) begin:adder_gen
                always@(posedge sclk or negedge s_rst_n) begin
                    if (s_rst_n == 1'b0)
                        data[stage][adder][ODATA_WIDTH-1:0] <= 'd0;
                    else begin
                        data[stage][adder][ST_WIDTH-1:0] <= data[stage-1][adder*2][(ST_WIDTH-1)-1:0] + data[stage-1][adder*2+1][(ST_WIDTH-1)-1:0];
                    end    
                end
            end
        end
    end
endgenerate

assign data_out = data[STAGES_NUM][0];

endmodule // AddTreeUnsigned
