`default_nettype none
`include "common_params.h"

module decode_phase #(
  parameter EW_LAYER = 1
) (
  input wire [`MICRO_W   -1:0] deq_opcode_head      ,
  input wire [`REG_ADDR_W-1:0] deq_reg_addr_d_head  ,
  input wire [`REG_ADDR_W-1:0] deq_reg_addr_s_head  ,
  input wire [`REG_ADDR_W-1:0] deq_reg_addr_t_head  ,
  input wire [`IMM_W     -1:0] deq_immediate_head   ,
  input wire [`BIT_MODE_W-1:0] deq_bit_mode_head    ,
  input wire [`ADDR_W    -1:0] deq_pc_head          ,
  output reg [`MICRO_W   -1:0] de_opcode            ,
  output reg [`REG_ADDR_W-1:0] de_reg_addr_d        ,
  output reg [`REG_ADDR_W-1:0] de_reg_addr_s        ,
  output reg [`REG_ADDR_W-1:0] de_reg_addr_t        ,
  output reg [`REG_W     -1:0] de_d                 ,
  output reg [`REG_W     -1:0] de_s                 ,
  output reg [`REG_W     -1:0] de_t                 ,
  output reg [`IMM_W     -1:0] de_immediate         ,
  output reg [`BIT_MODE_W-1:0] de_bit_mode          ,
  output reg [`ADDR_W    -1:0] de_pc                ,
  input wire [`REG_W     -1:0] gpr [`REG_N-1:0]     ,
  input wire                   forward_to_d_from_exe,
  input wire                   forward_to_s_from_exe,
  input wire                   forward_to_t_from_exe,
  input wire [EW_LAYER     :0] forward_to_d_from_wri,
  input wire [EW_LAYER     :0] forward_to_s_from_wri,
  input wire [EW_LAYER     :0] forward_to_t_from_wri,
  input wire [`REG_W     -1:0] exe_d                ,
  input wire [`REG_W     -1:0] wri_d[EW_LAYER:0]    ,
  input wire                   stall                ,
  input wire                   flush                ,
  input wire                   clk                  ,
  input wire                   rstn
);
  wire [8*5   -1:0] opcode_name =
    (de_opcode==`MICRO_NOP ) ? "NOP"  :
    (de_opcode==`MICRO_ADDI) ? "ADDI" :
    (de_opcode==`MICRO_ADD ) ? "ADD"  :
    (de_opcode==`MICRO_SB  ) ? "SB"   :
    (de_opcode==`MICRO_LB  ) ? "LB"   :
    (de_opcode==`MICRO_SD  ) ? "SD"   :
    (de_opcode==`MICRO_LD  ) ? "LD"   :
    (de_opcode==`MICRO_SQ  ) ? "SQ"   :
    (de_opcode==`MICRO_LQ  ) ? "LQ"   :
    (de_opcode==`MICRO_SLLI) ? "SLLI" :
    (de_opcode==`MICRO_JR  ) ? "JR"   :
    (de_opcode==`MICRO_MOV ) ? "MOV"  :
    (de_opcode==`MICRO_MOVI) ? "MOVI" :
    (de_opcode==`MICRO_CMP ) ? "CMP"  :
    (de_opcode==`MICRO_CMPI) ? "CMPI" :
    (de_opcode==`MICRO_XOR ) ? "XOR"  :
    (de_opcode==`MICRO_LEA ) ? "LEA"  : "???";

  wire [`REG_W-1:0] dec_d;
  wire [`REG_W-1:0] dec_s;
  wire [`REG_W-1:0] dec_t;

  always @(posedge clk) begin
    de_opcode      <=~rstn ? 0:flush ? 0:stall ? 0 :deq_opcode_head      ;
    de_reg_addr_d  <=~rstn ? 0:flush ? 0:stall ? 0 :deq_reg_addr_d_head  ;
    de_reg_addr_s  <=~rstn ? 0:flush ? 0:stall ? 0 :deq_reg_addr_s_head  ;
    de_reg_addr_t  <=~rstn ? 0:flush ? 0:stall ? 0 :deq_reg_addr_t_head  ;
    de_immediate   <=~rstn ? 0:flush ? 0:stall ? 0 :deq_immediate_head   ;
    de_bit_mode    <=~rstn ? 0:flush ? 0:stall ? 0 :deq_bit_mode_head    ;
    de_pc          <=~rstn ? 0:flush ? 0:stall ? 0 :deq_pc_head          ;
    de_d           <=~rstn ? 0:flush ? 0:stall ? 0 :dec_d                ;
    de_s           <=~rstn ? 0:flush ? 0:stall ? 0 :dec_s                ;
    de_t           <=~rstn ? 0:flush ? 0:stall ? 0 :dec_t                ;
  end
  
  decode_phase_value_decision #(
    EW_LAYER
  ) decode_phase_value_decision_1 (
    .opcode               (deq_opcode_head      ),
    .reg_addr_d           (deq_reg_addr_d_head  ),
    .reg_addr_s           (deq_reg_addr_s_head  ),
    .reg_addr_t           (deq_reg_addr_t_head  ),
    .gpr                  (gpr                  ),
    .forward_to_d_from_exe(forward_to_d_from_exe),
    .forward_to_s_from_exe(forward_to_s_from_exe),
    .forward_to_t_from_exe(forward_to_t_from_exe),
    .forward_to_d_from_wri(forward_to_d_from_wri),
    .forward_to_s_from_wri(forward_to_s_from_wri),
    .forward_to_t_from_wri(forward_to_t_from_wri),
    .exe_d                (exe_d                ),
    .wri_d                (wri_d                ),
    .d                    (dec_d                ),
    .s                    (dec_s                ),
    .t                    (dec_t                )
  );
endmodule


module decode_phase_value_decision #(
  parameter EW_LAYER = 1
) (
  input  wire [`OPCODE_W   -1:0] opcode,
  input  wire [`REG_ADDR_W -1:0] reg_addr_d,
  input  wire [`REG_ADDR_W -1:0] reg_addr_s,
  input  wire [`REG_ADDR_W -1:0] reg_addr_t,
  input  wire [`REG_W      -1:0] gpr [`REG_N-1:0],
  input  wire                    forward_to_d_from_exe,
  input  wire                    forward_to_s_from_exe,
  input  wire                    forward_to_t_from_exe,
  input  wire [EW_LAYER      :0] forward_to_d_from_wri,
  input  wire [EW_LAYER      :0] forward_to_s_from_wri,
  input  wire [EW_LAYER      :0] forward_to_t_from_wri,
  input  wire [`REG_W      -1:0] exe_d,
  input  wire [`REG_W      -1:0] wri_d[EW_LAYER:0],
  output wire [`REG_W      -1:0] d,
  output wire [`REG_W      -1:0] s,
  output wire [`REG_W      -1:0] t
);
  wire d_from_fpr, s_from_fpr, t_from_fpr;

  register_usage_table register_usage_table_1 (
    .opcode     (opcode),
    .d_from_fpr (d_from_fpr),
    .s_from_fpr (s_from_fpr),
    .t_from_fpr (t_from_fpr)
  );

  one_val_decision_following_forward_control #(
    EW_LAYER
  ) one_val_decision_following_forward_control_for_d (
    .reg_val         (gpr[reg_addr_d]),
    .forward_from_exe(forward_to_d_from_exe),
    .forward_from_wri(forward_to_d_from_wri),
    .exe_d           (exe_d),
    .wri_d           (wri_d),
    .source_val      (d)
  );
  
  one_val_decision_following_forward_control #(
    EW_LAYER
  ) one_val_decision_following_forward_control_for_s (
    .reg_val         (gpr[reg_addr_s]),
    .forward_from_exe(forward_to_s_from_exe),
    .forward_from_wri(forward_to_s_from_wri),
    .exe_d           (exe_d),
    .wri_d           (wri_d),
    .source_val      (s)
  );

  one_val_decision_following_forward_control #(
    EW_LAYER
  ) one_val_decision_following_forward_control_for_t (
    .reg_val         (gpr[reg_addr_t]),
    .forward_from_exe(forward_to_t_from_exe),
    .forward_from_wri(forward_to_t_from_wri),
    .exe_d           (exe_d),
    .wri_d           (wri_d),
    .source_val      (t)
  );
endmodule

module one_val_decision_following_forward_control #(
  parameter EW_LAYER = 1
) (
  input  wire [`REG_W      -1:0] reg_val,
  input  wire                    forward_from_exe,
  input  wire [EW_LAYER      :0] forward_from_wri,
  input  wire [`REG_W      -1:0] exe_d,
  input  wire [`REG_W      -1:0] wri_d[EW_LAYER:0],
  output wire [`REG_W      -1:0] source_val
);
  /************************************************
  * かなり読みづらくなっていますが,
  *
  * assign source_val =
  *   (forward_from_exe    ) ? exe_d     :
  *   (forward_from_wri[ 0]) ? wri_d[ 0] :
  *   (forward_from_wri[ 1]) ? wri_d[ 1] :
  *     .         .         .
  *     .         .         .
  *     .         .         .
  *   (forward_from_wri[EL]) ? wri_d[EL] : reg_val;
  *
  * という式を ELに関して一般化したものです.
  *
  */
  localparam EL = EW_LAYER;
  genvar i;

  wire [`REG_W-1:0] val_iter[EL:0];

  assign val_iter[EL] =(forward_from_wri[EL]) ? wri_d[EL] : reg_val;

  generate
  for(i=EL-1;i>=0;i=i-1) begin: hoge
    assign val_iter[i] = (forward_from_wri[i]) ? wri_d[i] : val_iter[i+1];
  end
  endgenerate

  assign source_val = (forward_from_exe) ? exe_d : val_iter[0];
endmodule

`default_nettype wire
