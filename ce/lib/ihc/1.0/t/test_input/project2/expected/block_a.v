
module block_a #(parameter DATA_WIDTH=3)(
    input [DATA_WIDTH-1:0] data_in,
    output [2:1] data_out_1,
    input  clk,
    input  rst,
);

/*AUTO_TEMPLATE instance\(\d+\)(
.data_out(data_out_1[$i1]]));
*/
)

module1 #(param DATA_WIDTH=3) instance1(
.data_in(data_in),
.data_out(data_out_1[1]),
.clk(clk),
.rst(rst)
);
module1 instance2(
.data_in(data_in),
.data_out(data_out_1[2]),
.clk(clk),
.rst(rst)
);

block_d stam(


);

endmodule
