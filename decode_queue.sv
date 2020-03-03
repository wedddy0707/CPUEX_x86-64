`default_nettype none
`include "common_params.h"

module decode_queue (
  input wire [`MICRO_W   -1:0] fet_opcode      [`MICRO_Q_N-1:0],
  input wire [`REG_ADDR_W-1:0] fet_reg_addr_d  [`MICRO_Q_N-1:0],
  input wire [`REG_ADDR_W-1:0] fet_reg_addr_s  [`MICRO_Q_N-1:0],
  input wire [`REG_ADDR_W-1:0] fet_reg_addr_t  [`MICRO_Q_N-1:0],
  input wire [`IMM_W     -1:0] fet_immediate   [`MICRO_Q_N-1:0],
  input wire [`BIT_MODE_W-1:0] fet_bit_mode    [`MICRO_Q_N-1:0],
  input wire                   fet_efl_mode    [`MICRO_Q_N-1:0],
  input wire [`ADDR_W    -1:0] fet_pc          [`MICRO_Q_N-1:0],
  input wire                   fet_inst_valid                  ,
  output reg [`MICRO_W   -1:0] deq_opcode_head                 ,
  output reg [`REG_ADDR_W-1:0] deq_reg_addr_d_head             ,
  output reg [`REG_ADDR_W-1:0] deq_reg_addr_s_head             ,
  output reg [`REG_ADDR_W-1:0] deq_reg_addr_t_head             ,
  output reg [`IMM_W     -1:0] deq_immediate_head              ,
  output reg [`BIT_MODE_W-1:0] deq_bit_mode_head               ,
  output reg                   deq_efl_mode_head               ,
  output reg [`ADDR_W    -1:0] deq_pc_head                     ,
  input wire                   stall                           ,
  input wire                   flush                           ,
  input wire                   clk                             ,
  input wire                   rstn                            //
);
  reg  [`MICRO_W    -1:0] deq_opcode      [`DEC_Q_N-1:0];
  reg  [`REG_ADDR_W -1:0] deq_reg_addr_d  [`DEC_Q_N-1:0];
  reg  [`REG_ADDR_W -1:0] deq_reg_addr_s  [`DEC_Q_N-1:0];
  reg  [`REG_ADDR_W -1:0] deq_reg_addr_t  [`DEC_Q_N-1:0];
  reg  [`IMM_W      -1:0] deq_immediate   [`DEC_Q_N-1:0];
  reg  [`BIT_MODE_W -1:0] deq_bit_mode    [`DEC_Q_N-1:0];
  reg                     deq_efl_mode    [`DEC_Q_N-1:0];
  reg  [`ADDR_W     -1:0] deq_pc          [`DEC_Q_N-1:0];
  
  assign deq_opcode_head        = deq_opcode       [0];
  assign deq_reg_addr_d_head    = deq_reg_addr_d   [0];
  assign deq_reg_addr_s_head    = deq_reg_addr_s   [0];
  assign deq_reg_addr_t_head    = deq_reg_addr_t   [0];
  assign deq_immediate_head     = deq_immediate    [0];
  assign deq_bit_mode_head      = deq_bit_mode     [0];
  assign deq_efl_mode_head      = deq_efl_mode     [0];
  assign deq_pc_head            = deq_pc           [0];

  wire [`MICRO_Q_N_W-1:0] fet_head_pre [`MICRO_Q_N-1:0];
  wire [`MICRO_Q_N_W-1:0] fet_head;
  wire [`MICRO_Q_N_W-1:0] fet_tail_pre [`MICRO_Q_N-1:0];
  wire [`MICRO_Q_N_W-1:0] fet_tail;
  wire [`MICRO_Q_N_W-1:0] deq_tail_pre [`MICRO_Q_N-1:0];
  wire [`MICRO_Q_N_W-1:0] deq_tail;
  
  assign fet_head_pre[`MICRO_Q_N-1] =`MICRO_Q_N-1;
  assign fet_tail_pre[           0] =           0;
  assign deq_tail_pre[           0] =           0;

  genvar i;
  integer j,k;
  
  generate begin
  for (i=`MICRO_Q_N-2;i>=0;i=i-1) begin: determine_fet_head
    assign fet_head_pre[i] =
      (fet_opcode[i]!=`MICRO_NOP) ?`MICRO_Q_N_W'(i):fet_head_pre[i+1];
  end
  for (i=1;i<`MICRO_Q_N;i=i+1)    begin: determine_fet_tail
    assign fet_tail_pre[i] =
      (fet_opcode[i]!=`MICRO_NOP) ?`MICRO_Q_N_W'(i):fet_tail_pre[i-1];
  end
  for (i=1;i<`DEC_Q_N;i=i+1)      begin: determine_deq_tail
    assign deq_tail_pre[i] =
      (deq_opcode[i]!=`MICRO_NOP) ?`DEC_Q_N_W'(i)  :deq_tail_pre[i-1];
  end
  end endgenerate

  assign fet_head = fet_head_pre[           0];
  assign fet_tail = fet_tail_pre[`MICRO_Q_N-1];
  assign deq_tail = deq_tail_pre[`MICRO_Q_N-1];

  always @(posedge clk) begin
    if (~rstn | flush) begin
      for (j=0;j<`DEC_Q_N;j=j+1) begin
        deq_opcode[j] <= `MICRO_NOP;
      end
    end else if (~stall) begin
      for (j=0;j<`DEC_Q_N-1;j=j+1) begin
        deq_opcode      [j] <= deq_opcode      [j+1];
        deq_reg_addr_d  [j] <= deq_reg_addr_d  [j+1];
        deq_reg_addr_s  [j] <= deq_reg_addr_s  [j+1];
        deq_reg_addr_t  [j] <= deq_reg_addr_t  [j+1];
        deq_immediate   [j] <= deq_immediate   [j+1];
        deq_bit_mode    [j] <= deq_bit_mode    [j+1];
        deq_efl_mode    [j] <= deq_efl_mode    [j+1];
        deq_pc          [j] <= deq_pc          [j+1];
      end

      if (fet_inst_valid) begin
        for (j=0;j<`DEC_Q_N;j=j+1) begin
          if (fet_head+j <= fet_tail) begin
            deq_opcode      [deq_tail+j] <= fet_opcode      [fet_head+j];
            deq_reg_addr_d  [deq_tail+j] <= fet_reg_addr_d  [fet_head+j];
            deq_reg_addr_s  [deq_tail+j] <= fet_reg_addr_s  [fet_head+j];
            deq_reg_addr_t  [deq_tail+j] <= fet_reg_addr_t  [fet_head+j];
            deq_immediate   [deq_tail+j] <= fet_immediate   [fet_head+j];
            deq_bit_mode    [deq_tail+j] <= fet_bit_mode    [fet_head+j];
            deq_efl_mode    [deq_tail+j] <= fet_efl_mode    [fet_head+j];
            deq_pc          [deq_tail+j] <= fet_pc          [fet_head+j];
          end
        end
      end
    end
  end
endmodule
`default_nettype wire
