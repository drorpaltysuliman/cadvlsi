module block_b #(parameter DATA_WIDTH=1)(parameter DATA_WIDTH = 5,
               parameter UUU= DATA_WITH+1,parameter LLL = 6)(
/* autoinput */
input  rst ,
input [DATA_WIDTH-1:0] data_in_out ,
input [DATA_W2-1:0] data_in ,
input   ,
/* auto output */
output  data_en ,
output  data_in_out_2 ,
input clk
);

/* auto wire */


/*AUTO_TEMPLATE instance2(
.data_in(data_out),
.data_\(\w+\)(data_in_$1)
);
*/

module1 #(.DATA_WIDTH(3),
          .BLA(5)) instance2(
.data_out_2(data_in_out_2),
.rst(rst),
.data_in(data_in_out),
.(),
.clk(clk)
);
module2 instance7(
.rst(rst),
.data_en(data_en),
.data_in(data_in),
.());

endmodule