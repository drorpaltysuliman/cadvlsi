module block_b (parameter DATA_WIDTH = 5,
               parameter UUU= DATA_WITH+1,parameter LLL = 6)(
/* autoinput */
input  rst ,
input [DATA_WIDTH-1:0] data_in ,
input  clk ,
/* auto output */
output  data_out ,
output  data_en ,
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
.clk(clk)
);
module2 instance7();

endmodule