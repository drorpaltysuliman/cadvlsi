module block_d  #(parameter DATA2=3,
parameter DATA_WIDTH=1,
parameter DATA_W2 = 5)(
/*autoinput*/
input [DATA_WIDTH-1:0] data_in_num_2 ,
input  rst ,
input  clk_en ,
input [DATA_WIDTH-1:0] data_in ,
input  clk ,
/*autooutput*/
output [DATA2:0] data_out_t_2 ,
output [2:0] data_out_t_7 ,
output  data_en );

/*autowire*/
/*AUTO_TEMPLATE ins\(t\)ance\(\d+\)(
.data_out(data_out_$i1_$i2));
*/

module1 #(.DATA_WIDTH(DATA_WIDTH)) instance2(
.data_in_num_2(data_in_num_2),
.data_out(data_out_t_2),
.rst(rst),
.clk(clk),
.data_in(data_in));


module2 #(.DATA_W2(DATA_W2)) instance7(
.data_out(data_out_t_7),
.rst(rst),
.clk_en(clk_en),
.data_en(data_en),
.clk(clk),
.data_in(data_in));

endmodule