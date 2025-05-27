/*
    --- Full Adder Group --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module FullAdder_Group (
    // Spikes-in
    input       [8 - 1 : 0]          i_Spikesdata         ,
    // Sum-out
    output wire [4 - 1 : 0]          o_Sum                
);

// -- method 1 --  >>> use 8 LUTs
// reg [4 - 1 : 0]          ones_count ; 
// assign o_Sum = ones_count;
// integer i;
// always @(*) begin
//     ones_count = 0;
//     for (i = 0; i < 8; i = i + 1) begin
//         ones_count = ones_count + i_Spikesdata[i];
//     end
// end

// -- method 2 -- >>> use 6 LUTs 
wire                    w_sum_1  ;
wire                    w_sum_2  ;
wire                    w_sum_3  ;
wire                    w_sum_4  ;
wire                    w_sum_5  ;
wire                    w_sum_6  ;
wire                    w_sum_7  ;

wire                    w_cout_1 ;
wire                    w_cout_2 ;
wire                    w_cout_3 ;
wire                    w_cout_4 ;
wire                    w_cout_5 ;
wire                    w_cout_6 ;
wire                    w_cout_7 ;

assign o_Sum = {w_cout_7, w_sum_7, w_sum_6, w_sum_4};

Full_adder u_Full_adder_m00(
    .i_A        ( i_Spikesdata[0]  ),
    .i_B        ( i_Spikesdata[1]  ),
    .i_Cin      ( i_Spikesdata[2]  ),
    .o_Sum      ( w_sum_1          ),
    .o_Cout     ( w_cout_1         )
);

Full_adder u_Full_adder_m01(
    .i_A        ( i_Spikesdata[3]  ),
    .i_B        ( i_Spikesdata[4]  ),
    .i_Cin      ( i_Spikesdata[5]  ),
    .o_Sum      ( w_sum_2          ),
    .o_Cout     ( w_cout_2         )
);

Full_adder u_Full_adder_m02(
    .i_A        ( w_sum_1          ),
    .i_B        ( w_sum_2          ),
    .i_Cin      ( i_Spikesdata[6]  ),
    .o_Sum      ( w_sum_3          ),
    .o_Cout     ( w_cout_3         )
);

Full_adder u_Full_adder_m03(
    .i_A        ( w_sum_3          ),
    .i_B        ( i_Spikesdata[7]  ),
    .i_Cin      ( 1'b0             ),
    .o_Sum      ( w_sum_4          ),
    .o_Cout     ( w_cout_4         )
);

Full_adder u_Full_adder_m04(
    .i_A        ( w_cout_1         ),
    .i_B        ( w_cout_3         ),
    .i_Cin      ( w_cout_2         ),
    .o_Sum      ( w_sum_5          ),
    .o_Cout     ( w_cout_5         )
);

Full_adder u_Full_adder_m05(
    .i_A        ( w_sum_5          ),
    .i_B        ( w_cout_4         ),
    .i_Cin      ( 1'b0             ),
    .o_Sum      ( w_sum_6          ),
    .o_Cout     ( w_cout_6         )
);

Full_adder u_Full_adder_m06(
    .i_A        ( w_cout_5         ),
    .i_B        ( w_cout_6         ),
    .i_Cin      ( 1'b0             ),
    .o_Sum      ( w_sum_7          ),
    .o_Cout     ( w_cout_7         )
);

endmodule // FullAdder_Group


