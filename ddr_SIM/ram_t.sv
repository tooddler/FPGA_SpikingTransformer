`include "define.v"
module ram_ddr (
    input                           clka     ,
    input      [`ADDR_SIZE-1 :0]    addra    ,
    input                           ena      ,
    input                           wea      ,
    input      [`DATA_WIDTH-1:0]    dina     ,
    output reg [`DATA_WIDTH-1:0]    douta
);


reg [`DATA_WIDTH-1:0] mem [0:`MEM_LENGTH-1];

`ifdef SIM_DETAIL
  initial begin
      //$readmemb("C:/Users/Qdream/OneDrive/Projects/IMG2COL/python/img2col/data/9tensor_bin.txt",mem);
      $readmemb($sformatf({`DATA_PATH,"%0dtensor_bin.txt"},`DETAIL_NUM),mem);
      //$readmemb({`DATA_PATH,"63tensor_bin.txt"},mem);
    end
`endif 

`ifdef SIM_ALL
  reg [`SIM_GROUP_NUMS_SIZE-1:0] count=0;
  always @(posedge ena) begin
      $readmemb($sformatf({`DATA_PATH,"%0dtensor_bin.txt"},count),mem);
      count<=count+1;
  end
`endif 

always@(posedge clka) begin
    if(ena) begin
        if(wea==1) begin
          mem[addra]<=dina;
        end
        else if(wea==0) begin
          douta<=mem[addra];
        end
    end
end
    

endmodule