/*
    func : Variable-length shift operations 
*/

module variable_shift (
    input       [7:0]               i_num_shifts , // Number of offset bits
    input       [25:0]              i_TargetData ,
    output reg  [25:0]              o_data_out   
);

always@(*) begin
    case(i_num_shifts)
        'd0 :       o_data_out = i_TargetData      ;      
        'd1 :       o_data_out = i_TargetData >> 1 ; 
        'd2 :       o_data_out = i_TargetData >> 2 ; 
        'd3 :       o_data_out = i_TargetData >> 3 ; 
        'd4 :       o_data_out = i_TargetData >> 4 ;
        'd5 :       o_data_out = i_TargetData >> 5 ;        
        'd6 :       o_data_out = i_TargetData >> 6 ;
        'd7 :       o_data_out = i_TargetData >> 7 ;
        'd8 :       o_data_out = i_TargetData >> 8 ;
        'd9 :       o_data_out = i_TargetData >> 9 ;
        'd10:       o_data_out = i_TargetData >> 10;
        'd11:       o_data_out = i_TargetData >> 11;
        'd12:       o_data_out = i_TargetData >> 12;
        'd13:       o_data_out = i_TargetData >> 13;
        'd14:       o_data_out = i_TargetData >> 14;
        'd15:       o_data_out = i_TargetData >> 15;
        'd16:       o_data_out = i_TargetData >> 16;
        'd17:       o_data_out = i_TargetData >> 17;
        'd18:       o_data_out = i_TargetData >> 18;
        'd19:       o_data_out = i_TargetData >> 19;
        'd20:       o_data_out = i_TargetData >> 20;
        'd21:       o_data_out = i_TargetData >> 21;
        'd22:       o_data_out = i_TargetData >> 22;
        'd23:       o_data_out = i_TargetData >> 23;
        'd24:       o_data_out = i_TargetData >> 24;
        'd25:       o_data_out = i_TargetData >> 25;
        default:    o_data_out = 26'd0;     
    endcase
end

endmodule //variable_shift
