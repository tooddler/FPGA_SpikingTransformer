/*
    --- Spikformer TOP --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module TOP (
    input                                                       s_clk                ,
    input                                                       s_rst                ,
    // ---- ConvWeightsLoad ---- \\
    output [0:0]                                                m00_axi_awid         ,
    output [31:0]                                               m00_axi_awaddr       ,
    output [7:0]                                                m00_axi_awlen        ,  
    output [2:0]                                                m00_axi_awsize       ,  
    output [1:0]                                                m00_axi_awburst      , 
    output                                                      m00_axi_awlock       ,  
    output [3:0]                                                m00_axi_awcache      ,  
    output [2:0]                                                m00_axi_awprot       ,  
    output [3:0]                                                m00_axi_awqos        ,  
    output [0:0]                                                m00_axi_awuser       ,  
    output                                                      m00_axi_awvalid      ,
    input                                                       m00_axi_awready      ,
    // Master Write Data
    output [63:0]                                               m00_axi_wdata        ,
    output [7:0]                                                m00_axi_wstrb        ,
    output                                                      m00_axi_wlast        ,
    output [0:0]                                                m00_axi_wuser        ,
    output                                                      m00_axi_wvalid       ,
    input                                                       m00_axi_wready       ,
    // Master Write Response
    input [0:0]                                                 m00_axi_bid          ,
    input [1:0]                                                 m00_axi_bresp        ,
    input [0:0]                                                 m00_axi_buser        ,
    input                                                       m00_axi_bvalid       ,
    output                                                      m00_axi_bready       ,
    // Master Read Address
    output [0:0]                                                m00_axi_arid         ,
    output [31:0]                                               m00_axi_araddr       ,
    output [7:0]                                                m00_axi_arlen        ,
    output [2:0]                                                m00_axi_arsize       , 
    output [1:0]                                                m00_axi_arburst      ,
    output [1:0]                                                m00_axi_arlock       ,
    output [3:0]                                                m00_axi_arcache      ,
    output [2:0]                                                m00_axi_arprot       ,
    output [3:0]                                                m00_axi_arqos        ,
    output [0:0]                                                m00_axi_aruser       ,
    output                                                      m00_axi_arvalid      ,
    input                                                       m00_axi_arready      ,
    // Master Read Data 
    input [0:0]                                                 m00_axi_rid          ,
    input [63:0]                                                m00_axi_rdata        ,
    input [1:0]                                                 m00_axi_rresp        ,
    input                                                       m00_axi_rlast        ,
    input [0:0]                                                 m00_axi_ruser        ,
    input                                                       m00_axi_rvalid       ,
    output                                                      m00_axi_rready       ,
    // ---- WeightsQuery ---- \\
    output [0:0]                                                m01_axi_awid         ,
    output [31:0]                                               m01_axi_awaddr       ,
    output [7:0]                                                m01_axi_awlen        ,  
    output [2:0]                                                m01_axi_awsize       ,  
    output [1:0]                                                m01_axi_awburst      , 
    output                                                      m01_axi_awlock       ,  
    output [3:0]                                                m01_axi_awcache      ,  
    output [2:0]                                                m01_axi_awprot       ,  
    output [3:0]                                                m01_axi_awqos        ,  
    output [0:0]                                                m01_axi_awuser       ,  
    output                                                      m01_axi_awvalid      ,
    input                                                       m01_axi_awready      ,
    // Master Write Data
    output [63:0]                                               m01_axi_wdata        ,
    output [7:0]                                                m01_axi_wstrb        ,
    output                                                      m01_axi_wlast        ,
    output [0:0]                                                m01_axi_wuser        ,
    output                                                      m01_axi_wvalid       ,
    input                                                       m01_axi_wready       ,
    // Master Write Response
    input [0:0]                                                 m01_axi_bid          ,
    input [1:0]                                                 m01_axi_bresp        ,
    input [0:0]                                                 m01_axi_buser        ,
    input                                                       m01_axi_bvalid       ,
    output                                                      m01_axi_bready       ,
    // Master Read Address
    output [0:0]                                                m01_axi_arid         ,
    output [31:0]                                               m01_axi_araddr       ,
    output [7:0]                                                m01_axi_arlen        ,
    output [2:0]                                                m01_axi_arsize       , 
    output [1:0]                                                m01_axi_arburst      ,
    output [1:0]                                                m01_axi_arlock       ,
    output [3:0]                                                m01_axi_arcache      ,
    output [2:0]                                                m01_axi_arprot       ,
    output [3:0]                                                m01_axi_arqos        ,
    output [0:0]                                                m01_axi_aruser       ,
    output                                                      m01_axi_arvalid      ,
    input                                                       m01_axi_arready      ,
    // Master Read Data 
    input [0:0]                                                 m01_axi_rid          ,
    input [63:0]                                                m01_axi_rdata        ,
    input [1:0]                                                 m01_axi_rresp        ,
    input                                                       m01_axi_rlast        ,
    input [0:0]                                                 m01_axi_ruser        ,
    input                                                       m01_axi_rvalid       ,
    output                                                      m01_axi_rready       ,
    // ---- WeightsKey ---- \\
    output [0:0]                                                m02_axi_awid         ,
    output [31:0]                                               m02_axi_awaddr       ,
    output [7:0]                                                m02_axi_awlen        ,  
    output [2:0]                                                m02_axi_awsize       ,  
    output [1:0]                                                m02_axi_awburst      , 
    output                                                      m02_axi_awlock       ,  
    output [3:0]                                                m02_axi_awcache      ,  
    output [2:0]                                                m02_axi_awprot       ,  
    output [3:0]                                                m02_axi_awqos        ,  
    output [0:0]                                                m02_axi_awuser       ,  
    output                                                      m02_axi_awvalid      ,
    input                                                       m02_axi_awready      ,
    // Master Write Data
    output [63:0]                                               m02_axi_wdata        ,
    output [7:0]                                                m02_axi_wstrb        ,
    output                                                      m02_axi_wlast        ,
    output [0:0]                                                m02_axi_wuser        ,
    output                                                      m02_axi_wvalid       ,
    input                                                       m02_axi_wready       ,
    // Master Write Response
    input [0:0]                                                 m02_axi_bid          ,
    input [1:0]                                                 m02_axi_bresp        ,
    input [0:0]                                                 m02_axi_buser        ,
    input                                                       m02_axi_bvalid       ,
    output                                                      m02_axi_bready       ,
    // Master Read Address
    output [0:0]                                                m02_axi_arid         ,
    output [31:0]                                               m02_axi_araddr       ,
    output [7:0]                                                m02_axi_arlen        ,
    output [2:0]                                                m02_axi_arsize       , 
    output [1:0]                                                m02_axi_arburst      ,
    output [1:0]                                                m02_axi_arlock       ,
    output [3:0]                                                m02_axi_arcache      ,
    output [2:0]                                                m02_axi_arprot       ,
    output [3:0]                                                m02_axi_arqos        ,
    output [0:0]                                                m02_axi_aruser       ,
    output                                                      m02_axi_arvalid      ,
    input                                                       m02_axi_arready      ,
    // Master Read Data 
    input [0:0]                                                 m02_axi_rid          ,
    input [63:0]                                                m02_axi_rdata        ,
    input [1:0]                                                 m02_axi_rresp        ,
    input                                                       m02_axi_rlast        ,
    input [0:0]                                                 m02_axi_ruser        ,
    input                                                       m02_axi_rvalid       ,
    output                                                      m02_axi_rready       ,
    // ---- WeightsValue ---- \\
    output [0:0]                                                m03_axi_awid         ,
    output [31:0]                                               m03_axi_awaddr       ,
    output [7:0]                                                m03_axi_awlen        ,  
    output [2:0]                                                m03_axi_awsize       ,  
    output [1:0]                                                m03_axi_awburst      , 
    output                                                      m03_axi_awlock       ,  
    output [3:0]                                                m03_axi_awcache      ,  
    output [2:0]                                                m03_axi_awprot       ,  
    output [3:0]                                                m03_axi_awqos        ,  
    output [0:0]                                                m03_axi_awuser       ,  
    output                                                      m03_axi_awvalid      ,
    input                                                       m03_axi_awready      ,
    // Master Write Data
    output [63:0]                                               m03_axi_wdata        ,
    output [7:0]                                                m03_axi_wstrb        ,
    output                                                      m03_axi_wlast        ,
    output [0:0]                                                m03_axi_wuser        ,
    output                                                      m03_axi_wvalid       ,
    input                                                       m03_axi_wready       ,
    // Master Write Response
    input [0:0]                                                 m03_axi_bid          ,
    input [1:0]                                                 m03_axi_bresp        ,
    input [0:0]                                                 m03_axi_buser        ,
    input                                                       m03_axi_bvalid       ,
    output                                                      m03_axi_bready       ,
    // Master Read Address
    output [0:0]                                                m03_axi_arid         ,
    output [31:0]                                               m03_axi_araddr       ,
    output [7:0]                                                m03_axi_arlen        ,
    output [2:0]                                                m03_axi_arsize       , 
    output [1:0]                                                m03_axi_arburst      ,
    output [1:0]                                                m03_axi_arlock       ,
    output [3:0]                                                m03_axi_arcache      ,
    output [2:0]                                                m03_axi_arprot       ,
    output [3:0]                                                m03_axi_arqos        ,
    output [0:0]                                                m03_axi_aruser       ,
    output                                                      m03_axi_arvalid      ,
    input                                                       m03_axi_arready      ,
    // Master Read Data 
    input [0:0]                                                 m03_axi_rid          ,
    input [63:0]                                                m03_axi_rdata        ,
    input [1:0]                                                 m03_axi_rresp        ,
    input                                                       m03_axi_rlast        ,
    input [0:0]                                                 m03_axi_ruser        ,
    input                                                       m03_axi_rvalid       ,
    output                                                      m03_axi_rready       
);

wire     [`DATA_WIDTH- 1 : 0]                 burst_read_data            ;
wire     [`ADDR_SIZE - 1 : 0]                 burst_read_addr            ;
wire     [`LEN_WIDTH - 1 : 0]                 burst_read_len             ;
wire                                          burst_read_req             ;
wire                                          burst_read_valid           ;
wire                                          burst_read_finish          ;

wire     [`DATA_WIDTH - 1 : 0]                w_Eyeriss_weight_in        ;
wire                                          w_Eyeriss_weight_valid     ;
wire                                          w_Eyeriss_weight_ready     ;

wire                                          w_SpikingEncoder_out_done  ;
wire     [`TIME_STEPS - 1 : 0]                w_SpikingEncoder_out       ;
wire                                          w_SpikingEncoder_out_valid ;

wire                                          w_data_valid               ;
wire     [`PATCH_EMBED_WIDTH - 1 : 0]         w_fmap                     ;
wire     [`PATCH_EMBED_WIDTH - 1 : 0]         w_patchdata                ;

wire     [`DATA_WIDTH- 1 : 0]                 M_lq_rd_burst_data         ;
wire     [`ADDR_SIZE - 1 : 0]                 M_lq_rd_burst_addr         ;
wire     [`LEN_WIDTH - 1 : 0]                 M_lq_rd_burst_len          ;
wire                                          M_lq_rd_burst_req          ;
wire                                          M_lq_rd_burst_valid        ;
wire                                          M_lq_rd_burst_finish       ;

wire     [`DATA_WIDTH- 1 : 0]                 M_lk_rd_burst_data         ;
wire     [`ADDR_SIZE - 1 : 0]                 M_lk_rd_burst_addr         ;
wire     [`LEN_WIDTH - 1 : 0]                 M_lk_rd_burst_len          ;
wire                                          M_lk_rd_burst_req          ;
wire                                          M_lk_rd_burst_valid        ;
wire                                          M_lk_rd_burst_finish       ;

wire     [`DATA_WIDTH- 1 : 0]                 M_lv_rd_burst_data         ;
wire     [`ADDR_SIZE - 1 : 0]                 M_lv_rd_burst_addr         ;
wire     [`LEN_WIDTH - 1 : 0]                 M_lv_rd_burst_len          ;
wire                                          M_lv_rd_burst_req          ;
wire                                          M_lv_rd_burst_valid        ;
wire                                          M_lv_rd_burst_finish       ;

// --------------- localBus2AXI --------------- \\ 
aq_axi_master u_aq_axi_master_ConvWeightsLoad (
    .ARESETN                     (~s_rst                                    ),
    .ACLK                        (s_clk                                     ),

    .M_AXI_AWID                  (m00_axi_awid                              ),
    .M_AXI_AWADDR                (m00_axi_awaddr                            ),
    .M_AXI_AWLEN                 (m00_axi_awlen                             ),
    .M_AXI_AWSIZE                (m00_axi_awsize                            ),
    .M_AXI_AWBURST               (m00_axi_awburst                           ),
    .M_AXI_AWLOCK                (m00_axi_awlock                            ),
    .M_AXI_AWCACHE               (m00_axi_awcache                           ),
    .M_AXI_AWPROT                (m00_axi_awprot                            ),
    .M_AXI_AWQOS                 (m00_axi_awqos                             ),
    .M_AXI_AWUSER                (m00_axi_awuser                            ),
    .M_AXI_AWVALID               (m00_axi_awvalid                           ),
    .M_AXI_AWREADY               (m00_axi_awready                           ),
    .M_AXI_WDATA                 (m00_axi_wdata                             ),
    .M_AXI_WSTRB                 (m00_axi_wstrb                             ),
    .M_AXI_WLAST                 (m00_axi_wlast                             ),
    .M_AXI_WUSER                 (m00_axi_wuser                             ),
    .M_AXI_WVALID                (m00_axi_wvalid                            ),
    .M_AXI_WREADY                (m00_axi_wready                            ),
    .M_AXI_BID                   (m00_axi_bid                               ),
    .M_AXI_BRESP                 (m00_axi_bresp                             ),
    .M_AXI_BUSER                 (m00_axi_buser                             ),
    .M_AXI_BVALID                (m00_axi_bvalid                            ),
    .M_AXI_BREADY                (m00_axi_bready                            ),
    .M_AXI_ARID                  (m00_axi_arid                              ),
    .M_AXI_ARADDR                (m00_axi_araddr                            ),
    .M_AXI_ARLEN                 (m00_axi_arlen                             ),
    .M_AXI_ARSIZE                (m00_axi_arsize                            ),
    .M_AXI_ARBURST               (m00_axi_arburst                           ),
    .M_AXI_ARLOCK                (m00_axi_arlock                            ),
    .M_AXI_ARCACHE               (m00_axi_arcache                           ),
    .M_AXI_ARPROT                (m00_axi_arprot                            ),
    .M_AXI_ARQOS                 (m00_axi_arqos                             ),
    .M_AXI_ARUSER                (m00_axi_aruser                            ),
    .M_AXI_ARVALID               (m00_axi_arvalid                           ),
    .M_AXI_ARREADY               (m00_axi_arready                           ),
    .M_AXI_RID                   (m00_axi_rid                               ),
    .M_AXI_RDATA                 (m00_axi_rdata                             ),
    .M_AXI_RRESP                 (m00_axi_rresp                             ),
    .M_AXI_RLAST                 (m00_axi_rlast                             ),
    .M_AXI_RUSER                 (m00_axi_ruser                             ),
    .M_AXI_RVALID                (m00_axi_rvalid                            ),
    .M_AXI_RREADY                (m00_axi_rready                            ),

    .MASTER_RST                  ( 1'b0                                     ), // not used write port
    
    .WR_START                    ( 1'b0                                     ),
    .WR_ADRS                     ( 'd0                                      ),
    .WR_LEN                      ( 'd0                                      ),
    .WR_READY                    (                                          ),
    .WR_FIFO_RE                  (                                          ),
    .WR_FIFO_EMPTY               ( 1'b0                                     ),
    .WR_FIFO_AEMPTY              ( 1'b0                                     ),
    .WR_FIFO_DATA                ( 'd0                                      ),
    .WR_DONE                     (                                          ),

    .RD_START                    (burst_read_req                            ),
    .RD_ADRS                     ({burst_read_addr,3'd0}                    ),
    .RD_LEN                      ({burst_read_len,3'd0}                     ),
    .RD_READY                    (                                          ),
    .RD_FIFO_WE                  (burst_read_valid                          ),
    .RD_FIFO_FULL                (1'b0                                      ),
    .RD_FIFO_AFULL               (1'b0                                      ),
    .RD_FIFO_DATA                (burst_read_data                           ),
    .RD_DONE                     (burst_read_finish                         ),
    .DEBUG                       (                                          )
);

aq_axi_master u_aq_axi_master_WeightsQuery (
    .ARESETN                     (~s_rst                                    ),
    .ACLK                        (s_clk                                     ),

    .M_AXI_AWID                  (m01_axi_awid                              ),
    .M_AXI_AWADDR                (m01_axi_awaddr                            ),
    .M_AXI_AWLEN                 (m01_axi_awlen                             ),
    .M_AXI_AWSIZE                (m01_axi_awsize                            ),
    .M_AXI_AWBURST               (m01_axi_awburst                           ),
    .M_AXI_AWLOCK                (m01_axi_awlock                            ),
    .M_AXI_AWCACHE               (m01_axi_awcache                           ),
    .M_AXI_AWPROT                (m01_axi_awprot                            ),
    .M_AXI_AWQOS                 (m01_axi_awqos                             ),
    .M_AXI_AWUSER                (m01_axi_awuser                            ),
    .M_AXI_AWVALID               (m01_axi_awvalid                           ),
    .M_AXI_AWREADY               (m01_axi_awready                           ),
    .M_AXI_WDATA                 (m01_axi_wdata                             ),
    .M_AXI_WSTRB                 (m01_axi_wstrb                             ),
    .M_AXI_WLAST                 (m01_axi_wlast                             ),
    .M_AXI_WUSER                 (m01_axi_wuser                             ),
    .M_AXI_WVALID                (m01_axi_wvalid                            ),
    .M_AXI_WREADY                (m01_axi_wready                            ),
    .M_AXI_BID                   (m01_axi_bid                               ),
    .M_AXI_BRESP                 (m01_axi_bresp                             ),
    .M_AXI_BUSER                 (m01_axi_buser                             ),
    .M_AXI_BVALID                (m01_axi_bvalid                            ),
    .M_AXI_BREADY                (m01_axi_bready                            ),
    .M_AXI_ARID                  (m01_axi_arid                              ),
    .M_AXI_ARADDR                (m01_axi_araddr                            ),
    .M_AXI_ARLEN                 (m01_axi_arlen                             ),
    .M_AXI_ARSIZE                (m01_axi_arsize                            ),
    .M_AXI_ARBURST               (m01_axi_arburst                           ),
    .M_AXI_ARLOCK                (m01_axi_arlock                            ),
    .M_AXI_ARCACHE               (m01_axi_arcache                           ),
    .M_AXI_ARPROT                (m01_axi_arprot                            ),
    .M_AXI_ARQOS                 (m01_axi_arqos                             ),
    .M_AXI_ARUSER                (m01_axi_aruser                            ),
    .M_AXI_ARVALID               (m01_axi_arvalid                           ),
    .M_AXI_ARREADY               (m01_axi_arready                           ),
    .M_AXI_RID                   (m01_axi_rid                               ),
    .M_AXI_RDATA                 (m01_axi_rdata                             ),
    .M_AXI_RRESP                 (m01_axi_rresp                             ),
    .M_AXI_RLAST                 (m01_axi_rlast                             ),
    .M_AXI_RUSER                 (m01_axi_ruser                             ),
    .M_AXI_RVALID                (m01_axi_rvalid                            ),
    .M_AXI_RREADY                (m01_axi_rready                            ),

    .MASTER_RST                  ( 1'b0                                     ), // not used write port
    .WR_START                    ( 1'b0                                     ),
    .WR_ADRS                     ( 'd0                                      ),
    .WR_LEN                      ( 'd0                                      ),
    .WR_READY                    (                                          ),
    .WR_FIFO_RE                  (                                          ),
    .WR_FIFO_EMPTY               ( 1'b0                                     ),
    .WR_FIFO_AEMPTY              ( 1'b0                                     ),
    .WR_FIFO_DATA                ( 'd0                                      ),
    .WR_DONE                     (                                          ),

    .RD_START                    (M_lq_rd_burst_req                         ),
    .RD_ADRS                     ({M_lq_rd_burst_addr,3'd0}                 ),
    .RD_LEN                      ({M_lq_rd_burst_len,3'd0}                  ),
    .RD_READY                    (                                          ),
    .RD_FIFO_WE                  (M_lq_rd_burst_valid                       ),
    .RD_FIFO_FULL                (1'b0                                      ),
    .RD_FIFO_AFULL               (1'b0                                      ),
    .RD_FIFO_DATA                (M_lq_rd_burst_data                        ),
    .RD_DONE                     (M_lq_rd_burst_finish                      ),
    .DEBUG                       (                                          )
);

aq_axi_master u_aq_axi_master_WeightsKey (
    .ARESETN                     (~s_rst                                    ),
    .ACLK                        (s_clk                                     ),

    .M_AXI_AWID                  (m02_axi_awid                              ),
    .M_AXI_AWADDR                (m02_axi_awaddr                            ),
    .M_AXI_AWLEN                 (m02_axi_awlen                             ),
    .M_AXI_AWSIZE                (m02_axi_awsize                            ),
    .M_AXI_AWBURST               (m02_axi_awburst                           ),
    .M_AXI_AWLOCK                (m02_axi_awlock                            ),
    .M_AXI_AWCACHE               (m02_axi_awcache                           ),
    .M_AXI_AWPROT                (m02_axi_awprot                            ),
    .M_AXI_AWQOS                 (m02_axi_awqos                             ),
    .M_AXI_AWUSER                (m02_axi_awuser                            ),
    .M_AXI_AWVALID               (m02_axi_awvalid                           ),
    .M_AXI_AWREADY               (m02_axi_awready                           ),
    .M_AXI_WDATA                 (m02_axi_wdata                             ),
    .M_AXI_WSTRB                 (m02_axi_wstrb                             ),
    .M_AXI_WLAST                 (m02_axi_wlast                             ),
    .M_AXI_WUSER                 (m02_axi_wuser                             ),
    .M_AXI_WVALID                (m02_axi_wvalid                            ),
    .M_AXI_WREADY                (m02_axi_wready                            ),
    .M_AXI_BID                   (m02_axi_bid                               ),
    .M_AXI_BRESP                 (m02_axi_bresp                             ),
    .M_AXI_BUSER                 (m02_axi_buser                             ),
    .M_AXI_BVALID                (m02_axi_bvalid                            ),
    .M_AXI_BREADY                (m02_axi_bready                            ),
    .M_AXI_ARID                  (m02_axi_arid                              ),
    .M_AXI_ARADDR                (m02_axi_araddr                            ),
    .M_AXI_ARLEN                 (m02_axi_arlen                             ),
    .M_AXI_ARSIZE                (m02_axi_arsize                            ),
    .M_AXI_ARBURST               (m02_axi_arburst                           ),
    .M_AXI_ARLOCK                (m02_axi_arlock                            ),
    .M_AXI_ARCACHE               (m02_axi_arcache                           ),
    .M_AXI_ARPROT                (m02_axi_arprot                            ),
    .M_AXI_ARQOS                 (m02_axi_arqos                             ),
    .M_AXI_ARUSER                (m02_axi_aruser                            ),
    .M_AXI_ARVALID               (m02_axi_arvalid                           ),
    .M_AXI_ARREADY               (m02_axi_arready                           ),
    .M_AXI_RID                   (m02_axi_rid                               ),
    .M_AXI_RDATA                 (m02_axi_rdata                             ),
    .M_AXI_RRESP                 (m02_axi_rresp                             ),
    .M_AXI_RLAST                 (m02_axi_rlast                             ),
    .M_AXI_RUSER                 (m02_axi_ruser                             ),
    .M_AXI_RVALID                (m02_axi_rvalid                            ),
    .M_AXI_RREADY                (m02_axi_rready                            ),

    .MASTER_RST                  ( 1'b0                                     ), // not used write port
    .WR_START                    ( 1'b0                                     ),
    .WR_ADRS                     ( 'd0                                      ),
    .WR_LEN                      ( 'd0                                      ),
    .WR_READY                    (                                          ),
    .WR_FIFO_RE                  (                                          ),
    .WR_FIFO_EMPTY               ( 1'b0                                     ),
    .WR_FIFO_AEMPTY              ( 1'b0                                     ),
    .WR_FIFO_DATA                ( 'd0                                      ),
    .WR_DONE                     (                                          ),

    .RD_START                    (M_lk_rd_burst_req                         ),
    .RD_ADRS                     ({M_lk_rd_burst_addr,3'd0}                 ),
    .RD_LEN                      ({M_lk_rd_burst_len,3'd0}                  ),
    .RD_READY                    (                                          ),
    .RD_FIFO_WE                  (M_lk_rd_burst_valid                       ),
    .RD_FIFO_FULL                (1'b0                                      ),
    .RD_FIFO_AFULL               (1'b0                                      ),
    .RD_FIFO_DATA                (M_lk_rd_burst_data                        ),
    .RD_DONE                     (M_lk_rd_burst_finish                      ),
    .DEBUG                       (                                          )
);

aq_axi_master u_aq_axi_master_WeightsValue (
    .ARESETN                     (~s_rst                                    ),
    .ACLK                        (s_clk                                     ),

    .M_AXI_AWID                  (m03_axi_awid                              ),
    .M_AXI_AWADDR                (m03_axi_awaddr                            ),
    .M_AXI_AWLEN                 (m03_axi_awlen                             ),
    .M_AXI_AWSIZE                (m03_axi_awsize                            ),
    .M_AXI_AWBURST               (m03_axi_awburst                           ),
    .M_AXI_AWLOCK                (m03_axi_awlock                            ),
    .M_AXI_AWCACHE               (m03_axi_awcache                           ),
    .M_AXI_AWPROT                (m03_axi_awprot                            ),
    .M_AXI_AWQOS                 (m03_axi_awqos                             ),
    .M_AXI_AWUSER                (m03_axi_awuser                            ),
    .M_AXI_AWVALID               (m03_axi_awvalid                           ),
    .M_AXI_AWREADY               (m03_axi_awready                           ),
    .M_AXI_WDATA                 (m03_axi_wdata                             ),
    .M_AXI_WSTRB                 (m03_axi_wstrb                             ),
    .M_AXI_WLAST                 (m03_axi_wlast                             ),
    .M_AXI_WUSER                 (m03_axi_wuser                             ),
    .M_AXI_WVALID                (m03_axi_wvalid                            ),
    .M_AXI_WREADY                (m03_axi_wready                            ),
    .M_AXI_BID                   (m03_axi_bid                               ),
    .M_AXI_BRESP                 (m03_axi_bresp                             ),
    .M_AXI_BUSER                 (m03_axi_buser                             ),
    .M_AXI_BVALID                (m03_axi_bvalid                            ),
    .M_AXI_BREADY                (m03_axi_bready                            ),
    .M_AXI_ARID                  (m03_axi_arid                              ),
    .M_AXI_ARADDR                (m03_axi_araddr                            ),
    .M_AXI_ARLEN                 (m03_axi_arlen                             ),
    .M_AXI_ARSIZE                (m03_axi_arsize                            ),
    .M_AXI_ARBURST               (m03_axi_arburst                           ),
    .M_AXI_ARLOCK                (m03_axi_arlock                            ),
    .M_AXI_ARCACHE               (m03_axi_arcache                           ),
    .M_AXI_ARPROT                (m03_axi_arprot                            ),
    .M_AXI_ARQOS                 (m03_axi_arqos                             ),
    .M_AXI_ARUSER                (m03_axi_aruser                            ),
    .M_AXI_ARVALID               (m03_axi_arvalid                           ),
    .M_AXI_ARREADY               (m03_axi_arready                           ),
    .M_AXI_RID                   (m03_axi_rid                               ),
    .M_AXI_RDATA                 (m03_axi_rdata                             ),
    .M_AXI_RRESP                 (m03_axi_rresp                             ),
    .M_AXI_RLAST                 (m03_axi_rlast                             ),
    .M_AXI_RUSER                 (m03_axi_ruser                             ),
    .M_AXI_RVALID                (m03_axi_rvalid                            ),
    .M_AXI_RREADY                (m03_axi_rready                            ),

    .MASTER_RST                  ( 1'b0                                     ), // not used write port
    .WR_START                    ( 1'b0                                     ),
    .WR_ADRS                     ( 'd0                                      ),
    .WR_LEN                      ( 'd0                                      ),
    .WR_READY                    (                                          ),
    .WR_FIFO_RE                  (                                          ),
    .WR_FIFO_EMPTY               ( 1'b0                                     ),
    .WR_FIFO_AEMPTY              ( 1'b0                                     ),
    .WR_FIFO_DATA                ( 'd0                                      ),
    .WR_DONE                     (                                          ),

    .RD_START                    (M_lv_rd_burst_req                         ),
    .RD_ADRS                     ({M_lv_rd_burst_addr,3'd0}                 ),
    .RD_LEN                      ({M_lv_rd_burst_len,3'd0}                  ),
    .RD_READY                    (                                          ),
    .RD_FIFO_WE                  (M_lv_rd_burst_valid                       ),
    .RD_FIFO_FULL                (1'b0                                      ),
    .RD_FIFO_AFULL               (1'b0                                      ),
    .RD_FIFO_DATA                (M_lv_rd_burst_data                        ),
    .RD_DONE                     (M_lv_rd_burst_finish                      ),
    .DEBUG                       (                                          )
);

// --------------- SpikingEncoder --------------- \\ 
SpikingEncoder u_SpikingEncoder(
    .s_clk                          ( s_clk                                 ),
    .s_rst                          ( s_rst                                 ),

    .network_cal_done               ( 1'b0                                  ),

    .burst_read_data                ( burst_read_data                       ),
    .burst_read_addr                ( burst_read_addr                       ),
    .burst_read_len                 ( burst_read_len                        ),
    .burst_read_req                 ( burst_read_req                        ),
    .burst_read_valid               ( burst_read_valid                      ),
    .burst_read_finish              ( burst_read_finish                     ),
    
    .Eyeriss_weight_in              ( w_Eyeriss_weight_in                   ),
    .Eyeriss_weight_valid           ( w_Eyeriss_weight_valid                ),
    .Eyeriss_weight_ready           ( w_Eyeriss_weight_ready                ),
    .i_weight_load_done             ( 1'b0                                  ),

    .o_SpikingEncoder_out_done      ( w_SpikingEncoder_out_done             ),
    .o_SpikingEncoder_out           ( w_SpikingEncoder_out                  ),
    .o_SpikingEncoder_out_valid     ( w_SpikingEncoder_out_valid            )
);

// --------------- Simple Eyeriss --------------- \\ 
simple_eyeriss_top u_simple_eyeriss_top(
    .s_clk                          ( s_clk                                 ),
    .s_rst                          ( s_rst                                 ),

    .SPS_part_done                  ( 1'b0                                  ),

    .weight_in                      ( w_Eyeriss_weight_in                   ),
    .weight_valid                   ( w_Eyeriss_weight_valid                ),
    .o_weight_ready                 ( w_Eyeriss_weight_ready                ),

    .SpikingEncoder_out_done        ( w_SpikingEncoder_out_done             ),
    .SpikingEncoder_out             ( w_SpikingEncoder_out                  ),
    .SpikingEncoder_out_valid       ( w_SpikingEncoder_out_valid            ),

    .o_data_valid                   ( w_data_valid                          ),
    .o_fmap                         ( w_fmap                                ),
    .o_patchdata                    ( w_patchdata                           )
);

// --------------- Transformer --------------- \\ 
TOP_Transformer u_TOP_Transformer(
    .s_clk                          ( s_clk                                 ),
    .s_rst                          ( s_rst                                 ),

    .i_load_w_finish                ( 1'b0                                  ),

    .i_data_valid                   ( w_data_valid                          ),
    .i_fmap                         ( w_fmap                                ),
    .i_patchdata                    ( w_patchdata                           ),

    .M_lq_rd_burst_data             ( M_lq_rd_burst_data                    ),
    .M_lq_rd_burst_addr             ( M_lq_rd_burst_addr                    ),
    .M_lq_rd_burst_len              ( M_lq_rd_burst_len                     ),
    .M_lq_rd_burst_req              ( M_lq_rd_burst_req                     ),
    .M_lq_rd_burst_valid            ( M_lq_rd_burst_valid                   ),
    .M_lq_rd_burst_finish           ( M_lq_rd_burst_finish                  ),

    .M_lk_rd_burst_data             ( M_lk_rd_burst_data                    ),
    .M_lk_rd_burst_addr             ( M_lk_rd_burst_addr                    ),
    .M_lk_rd_burst_len              ( M_lk_rd_burst_len                     ),
    .M_lk_rd_burst_req              ( M_lk_rd_burst_req                     ),
    .M_lk_rd_burst_valid            ( M_lk_rd_burst_valid                   ),
    .M_lk_rd_burst_finish           ( M_lk_rd_burst_finish                  ),

    .M_lv_rd_burst_data             ( M_lv_rd_burst_data                    ),
    .M_lv_rd_burst_addr             ( M_lv_rd_burst_addr                    ),
    .M_lv_rd_burst_len              ( M_lv_rd_burst_len                     ),
    .M_lv_rd_burst_req              ( M_lv_rd_burst_req                     ),
    .M_lv_rd_burst_valid            ( M_lv_rd_burst_valid                   ),
    .M_lv_rd_burst_finish           ( M_lv_rd_burst_finish                  )
);

endmodule


