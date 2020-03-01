`default_nettype none
`include "common_params.h"

module register_usage_table (
  input  wire [`OPCODE_W-1:0] opcode,
  output wire d_from_gpr,
  output wire d_from_fpr,
  output wire d_to_gpr,
  output wire d_to_fpr,
  output wire s_from_gpr,
  output wire s_from_fpr,
  output wire t_from_gpr,
  output wire t_from_fpr,
  output wire   to_eflags,
  output wire from_eflags
);
  localparam from_gd = 10'b1000000000;
  localparam from_fd = 10'b0100000000;
  localparam   to_gd = 10'b0010000000;
  localparam   to_fd = 10'b0001000000;
  localparam      gs = 10'b0000100000;
  localparam      fs = 10'b0000010000;
  localparam      gt = 10'b0000001000;
  localparam      ft = 10'b0000000100;
  localparam from_ef = 10'b0000000010;
  localparam   to_ef = 10'b0000000001;
  localparam nothing = 10'b0000000000;

  wire [9:0] select =
    (opcode==`MICRO_NOP ) ?                     nothing     :
    (opcode==`MICRO_ADDI) ?   to_gd | gs                    :
    (opcode==`MICRO_ADD ) ?   to_gd | gs | gt               :
    (opcode==`MICRO_SB  ) ? from_gd | gs                    :
    (opcode==`MICRO_SD  ) ? from_gd | gs                    :
    (opcode==`MICRO_SQ  ) ? from_gd | gs                    :
    (opcode==`MICRO_LB  ) ?   to_gd | gs                    :
    (opcode==`MICRO_LD  ) ?   to_gd | gs                    :
    (opcode==`MICRO_LQ  ) ?   to_gd | gs                    :
    (opcode==`MICRO_SLLI) ?   to_gd | gs                    :
    (opcode==`MICRO_JR  ) ? from_gd                         :
    (opcode==`MICRO_MOV ) ?   to_gd |      gt               :
    (opcode==`MICRO_MOVI) ?   to_gd                         :
    (opcode==`MICRO_CMP ) ?           gs | gt |   to_eflags :
    (opcode==`MICRO_CMPI) ?                gt |   to_eflags :
    (opcode==`MICRO_XOR ) ?   to_gd | gs | gt               :
    (opcode==`MICRO_LEA ) ?   to_gd | gs                    : nothing;

  assign {
    d_from_gpr,
    d_from_fpr,
    d_to_gpr,
    d_to_fpr,
    s_from_gpr,
    s_from_fpr,
    t_from_gpr,
    t_from_fpr,
    from_eflags,
    to_eflags } = select;
endmodule

/**********************************************
* condition_clarifier:
*   EFLAGSのようわからん情報を
*   私でも理解できるようにする信号にしてくれる
*/
module condition_clarifier (
  input wire [`REG_W-1:0] eflags          ,
  output reg              above           ,
  output reg              above_or_equal  ,
  output reg              below           ,
  output reg              below_or_equal  ,
  output reg              carry           ,
  output reg              equal           ,
  output reg              greater         ,
  output reg              greater_or_equal,
  output reg              less            ,
  output reg              less_or_equal   ,
  output reg              overflow        ,
  output reg              parity          ,
  output reg              sign            ,
  output reg              zero            //
);
  wire cf = eflags[`EFLAGS_CF]; // Carry Flag
  wire zf = eflags[`EFLAGS_ZF]; // Zero  Flag
  wire of = eflags[`EFLAGS_OF]; // Overflow
  wire sf = eflags[`EFLAGS_SF]; // Sign  Flag
  wire pf = eflags[`EFLAGS_PF]; // Sign  Flag

  // 最適化に期待して可読性重視
  assign zero             = zf                       ;
  assign carry            = cf                       ;
  assign overflow         = of                       ;
  assign sign             = sf                       ;
  assign parity           = pf                       ;
  assign equal            = zero                     ;
  assign greater_or_equal = sign==overflow           ;
  assign greater          = greater_or_equal & ~equal;
  assign less             =~greater_or_equal         ;
  assign less_or_equal    =~greater                  ;
  assign above            =~carry & ~equal           ;
  assign above_or_equal   = above |  equal           ;
  assign below            =~above_or_equal           ;
  assign below_or_equal   =~above                    ;
  
endmodule

module echo_assertion #(
  parameter LATENCY   = 2'd1,
  parameter IMMEDIATE = 1'd1
) (
  input  wire        trigger,
  output wire        assertion,
  input  wire        clk,
  input  wire        rstn
);
  reg [ 1:0] count_down;

  assign assertion = (IMMEDIATE&trigger)|(|count_down);

  always @(posedge clk) begin
    count_down <= (~rstn           ) ?       0 :
                  (trigger         ) ? LATENCY :
                  (count_down==2'd3) ?       2 :
                  (count_down==2'd2) ?       1 : 0;
  end
endmodule

module load_inst_detector (
  input wire [`OPCODE_W-1:0] opcode,
  output reg                 is_load_inst
);
  assign is_load_inst =
    (opcode==`MICRO_LB)|(opcode==`MICRO_LD)|(opcode==`MICRO_LQ);
endmodule

`default_nettype wire
