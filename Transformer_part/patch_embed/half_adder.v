/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : half adder
*/

module half_adder (
    input                       i_data0 ,
    input                       i_data1 ,

    output                      o_sum   ,
    output                      o_carry
);

assign o_sum   = i_data0 ^ i_data1;
assign o_carry = i_data0 & i_data1;

endmodule // half_adder
