module block_d #(parameter DATA_W2 = 5)(
    input [DATA_W2-1:0] data_in,
    output [2:0] data_out_t_2,
    output [DATA2:0] data_out_t_7,
    output data_en,
    input  clk,
    input  rst,
);

/*AUTO_TEMPLATE ins\(t\)ance\(\d+\)(
.data_out(data_out_$i1_$i2)
*/

module1 #(.DATA_WIDTH(DATA_WIDTH)) instance2(
.data_in(data_in),
.data_out(data_out_t_2),
.clk(clk),
.rst(rst)
.clk(clk));


module2 #(.DATA_W2(DATA_W2)) instance7(
.data_in(data_in),
.data_out(data_out_t_7),
.data_en(data_en),
.clk(clk),
.rst(rst),
);

endmodule
