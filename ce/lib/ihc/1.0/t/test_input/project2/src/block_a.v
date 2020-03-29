module block_a #(parameter DATA2=3,
parameter DATA_WIDTH=1) (
/*autoinput*/
input [DATA_WIDTH-1:0] data_in_num_2 ,
input  rst ,
input  clk_en ,
input [DATA_WIDTH-1:0] data_in ,
input  clk , 
/*autooutput*/
output [DATA2:0] data_out_t_2 ,
output [1:0] data_out_1 ,
output [2:0] data_out_t_7 ,
output  data_en );

/*autowire*/ 


/*AUTO_TEMPLATE #(.DATA2(2)) instance\(\d+\)(
.data_out_2(data_out_2 [2*$i1-:2]),
.data_out(data_out_1 [$i1 ]));
*/
)

module1 #(param DATA_WIDTH=3) instance0(
.data_in_num_2(data_in_num_2),
.data_out(data_out_1[0]),
.rst(rst),
.clk(clk),
.data_in(data_in));
module1 instance1(
.data_in_num_2(data_in_num_2),
.data_out(data_out_1[1]),
.rst(rst),
.clk(clk),
.data_in(data_in));

block_d stam(
.data_in_num_2(data_in_num_2),
.data_out_t_7(data_out_t_7),
.clk_en(clk_en),
.clk(clk),
.data_out_t_2(data_out_t_2),
.rst(rst),
.data_en(data_en),
.data_in(data_in));

endmodule