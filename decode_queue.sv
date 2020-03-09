`default_nettype none
`include "common_params.h"

module decode_queue (
  input  miinst_t fet_miinst [`MQ_N-1:0],
  input  logic    fet_valid             ,
  output miinst_t deq_miinst_head       ,
  input wire      stall                 ,
  input wire      flush                 ,
  input wire      clk                   ,
  input wire      rstn                  //
);
  miinst_t deq_miinst [`DQ_N-1:0];
 
  assign deq_miinst_head = deq_miinst[0]; 

  wire [`MQ_N_W-1:0] fet_head_pre [`MQ_N-1:0];
  wire [`MQ_N_W-1:0] fet_head;
  wire [`MQ_N_W-1:0] fet_tail_pre [`MQ_N-1:0];
  wire [`MQ_N_W-1:0] fet_tail;
  wire [`MQ_N_W-1:0] deq_tail_pre [`MQ_N-1:0];
  wire [`MQ_N_W-1:0] deq_tail;
  
  assign fet_head_pre[`MQ_N-1] =`MQ_N-1;
  assign fet_tail_pre[      0] =      0;
  assign deq_tail_pre[      0] =      0;

  genvar i;
  integer j,k;
  
  generate begin
  for (i=`MQ_N-2;i>=0;i=i-1) begin: determine_fet_head
    assign fet_head_pre[i] =
      (fet_miinst[i].op!=MIOP_NOP) ? `MQ_N_W'(i):fet_head_pre[i+1];
  end
  for (i=1;i<`MQ_N;i=i+1)    begin: determine_fet_tail
    assign fet_tail_pre[i] =
      (fet_miinst[i].op!=MIOP_NOP) ? `MQ_N_W'(i):fet_tail_pre[i-1];
  end
  for (i=1;i<`DQ_N;i=i+1)    begin: determine_deq_tail
    assign deq_tail_pre[i] =
      (deq_miinst[i].op!=MIOP_NOP) ? `DQ_N_W'(i):deq_tail_pre[i-1];
  end
  end endgenerate

  assign fet_head = fet_head_pre[      0];
  assign fet_tail = fet_tail_pre[`MQ_N-1];
  assign deq_tail = deq_tail_pre[`MQ_N-1];

  always @(posedge clk) begin
    if (~rstn | flush) begin
      for (j=0;j<`DQ_N;j=j+1) begin
        deq_miinst[j].op <= MIOP_NOP;
      end
    end else if (~stall) begin
      for (j=0;j<`DQ_N-1;j=j+1) begin
        deq_miinst[j] <= deq_miinst[j+1];
      end

      if (fet_valid) begin
        for (j=0;j<`DQ_N;j=j+1) begin
          if (fet_head+j <= fet_tail) begin
            deq_miinst[deq_tail+j] <= fet_miinst[fet_head+j];
          end
        end
      end
    end
  end
endmodule
`default_nettype wire
