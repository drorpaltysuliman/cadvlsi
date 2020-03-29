//-----------------------------------------------------
// Design Name : uart 
// File Name   : uart.v
// Function    : Simple UART
// Coder       : Deepak Kumar Tala
//-----------------------------------------------------
module uart (
reset          ,
txclk          ,
ld_tx_data     ,
tx_data        ,
tx_enable      ,
tx_out         ,
tx_empty       ,
rxclk          ,
uld_rx_data    ,
rx_data        ,
rx_enable      ,
rx_in          ,
rx_empty
);
// Port declarations
input        reset,txclk,  ld_tx_data     ;
input  [7:0] tx_data        ;
input        tx_enable      ;


// UART TX Logic
always @@@@ (posedge txclk or posedge reset)
if (reset) begin
  tx_reg        <= 0;
  tx_empty      <= 1;
  tx_over_run   <= 0;
  tx_out        <= 1;
  tx_cnt        <= 0;
end else begin
   if (ld_tx_data) begin
      if (!tx_empty) begin
        tx_over_run <= 0;
      end else begin
        tx_reg   <= tx_data;
        tx_empty <= 0;
      end
   end
   if (tx_enable && !tx_empty) begin
     tx_cnt <= tx_cnt + 1;
     if (tx_cnt == 0) begin
       tx_out <= 0;
     end
     if (tx_cnt > 0 && tx_cnt < 9) begin
        tx_out <= tx_reg[tx_cnt -1];
     end
     if (tx_cnt == 9) begin
       tx_out <= 1;
       tx_cnt <= 0;
       tx_empty <= 1;
     end
   end
   if (!tx_enable) begin
     tx_cnt <= 0;
   end
end

endmodule



