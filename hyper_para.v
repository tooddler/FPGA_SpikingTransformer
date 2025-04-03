/*
    --- hyp --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

// simulation param
`define     SIM
`define     MEM_LENGTH                  2147483641       // 32'h8000_0000 - 1'b1
`define     CLK_PERIOD                  10               // ns

/* --------------  IMG SIZE --------------*/
`define     IMG_BASEADDR                32'h1000_0000    // 268435456
`define     IMG_WIDTH                   32
`define     IMG_HIGH                    32
`define     IMG_BURST_LENS              'd16
`define     IMG_QUAN_SCALE              6                // SCALE = Log2(64)
`define     PSUM_RAM_DEPTH              9                

/* -------------- DDR --------------*/
`define     LEN_WIDTH                   10
`define     ADDR_SIZE                   32
`define     DATA_WIDTH                  64

/* -------------- DATA & WEIGHT --------------*/
`define     QUAN_BITS                   8
`define     ADD9_ALL_BITS               25 

/* -------------- SPS PART CODE --------------*/        
`define     MAXPOOL_CODE                15'h08
`define     CONV_CODE                   15'h01
`define     LEN_CODE                    6                // 4 x Conv , 2 x Maxpool

/* --------------  network parameters addr --------------*/
`define     TIME_STEPS                  4
`define     PADDING_PARAM               0
// layer 1 : spiking-encoder
`define     PE_ROW                      3                // kernel size = 3
`define     PE_COL                      3    
`define     PE_NUM                      3

`define     CONV1_BASEADDR              32'h0000_0000    // 32'h0000_0000    // total: 48 x 3 x 3 x 3 = 1296 bytes  (1296 / 8 = 162)
`define     CONV1_BURST_LENS            'd8
`define     CONV1_KERNEL_CHNNLS         48
`define     CONV1_WEIGHT_SCALE          5                // SCALE = Log2(32)
`define     CONV1_BIAS_SCALE            6                // SCALE = Log2(64)
`define     CONV1_THRESHOLD             'd2048           // ADD9_ALL_BITS -> Q13.11 -> 25'h800

// spiking conv (simple eyeriss array)
`define     ERS_PE_SIZE                 3                // array size == 3 x 3  
`define     ERS_PE_NUM                  8                // array num  == 8
`define     ERS_NEED_ROW_NUM            5               
`define     ERS_MAX_WIDTH               21               // 8 bit + log2(9) + log2(384) --> 21 bit

// MaxPool2d
`define     MAXPOOL2D_NUM               16               // nums for cal unit

/* -------------- systolic array --------------*/
`define     PATCH_EMBED_WIDTH           32               // IMG_WIDTH / 4,  TIME_STEPS == 4
`define     SYSTOLIC_UNIT_NUM           16               //  > 8
`define     SYSTOLIC_DATA_WIDTH         8                // 2 bit * TIME_STEPS = 8 bit
`define     SYSTOLIC_WEIGHT_WIDTH       8
// e.g. A(M x K) B(K x N)  to avaid overflow : 
// psum_width = SYSTOLIC_DATA_WIDTH / TIME_STEPS * 8bit(weight) + log2(K)
`define     SYSTOLIC_PSUM_WIDTH         80               // 20 bit * TIME_STEPS = 64 bit    
// qkv_linearWeights
`define     WEIGHTS_Q_BASEADDR          32'h2000_0000    // end -> 32'h2002_4000
`define     WEIGHTS_K_BASEADDR          32'h2003_0000    // end -> 32'h2005_4000
`define     WEIGHTS_V_BASEADDR          32'h2006_0000    // end -> 32'h2007_4000
`define     FINAL_FMAPS_CHNNLS          384
`define     FINAL_FMAPS_WIDTH           64
`define     MULTI_HEAD_NUMS             12
