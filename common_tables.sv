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
    (opcode==`MICRO_NOP  ) ?                             nothing :
    (opcode==`MICRO_ADD  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_SUB  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_ADC  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_SBB  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_MUL  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_DIV  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_AND  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_OR   ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_XOR  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_SLL  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_SRL  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_SRA  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (opcode==`MICRO_ADDI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_SUBI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_ADCI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_SBBI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_MULI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_DIVI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_ANDI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_ORI  ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_XORI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_SLLI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_SRLI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_SRAI ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_LB   ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_LW   ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_LD   ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_LQ   ) ?   to_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_SB   ) ? from_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_SW   ) ? from_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_SD   ) ? from_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_SQ   ) ? from_gd | gs      | from_ef | to_ef :
    (opcode==`MICRO_J    ) ?                             nothing :
    (opcode==`MICRO_JR   ) ? from_gd                             :
    (opcode==`MICRO_JA   ) ?                     from_ef         :
    (opcode==`MICRO_JAE  ) ?                     from_ef         :
    (opcode==`MICRO_JB   ) ?                     from_ef         :
    (opcode==`MICRO_JBE  ) ?                     from_ef         :
    (opcode==`MICRO_JC   ) ?                     from_ef         :
    (opcode==`MICRO_JE   ) ?                     from_ef         :
    (opcode==`MICRO_JG   ) ?                     from_ef         :
    (opcode==`MICRO_JGE  ) ?                     from_ef         :
    (opcode==`MICRO_JL   ) ?                     from_ef         :
    (opcode==`MICRO_JLE  ) ?                     from_ef         :
    (opcode==`MICRO_JO   ) ?                     from_ef         :
    (opcode==`MICRO_JP   ) ?                     from_ef         :
    (opcode==`MICRO_JS   ) ?                     from_ef         :
    (opcode==`MICRO_JNE  ) ?                     from_ef         :
    (opcode==`MICRO_JNP  ) ?                     from_ef         :
    (opcode==`MICRO_JNS  ) ?                     from_ef         :
    (opcode==`MICRO_JNO  ) ?                     from_ef         :
    (opcode==`MICRO_JCX  ) ?                     from_ef         :
    (opcode==`MICRO_MOV  ) ?   to_gd |      gt                   :
    (opcode==`MICRO_MOVI ) ?   to_gd                             :
    (opcode==`MICRO_CMP  ) ?           gs | gt | from_ef | to_ef :
    (opcode==`MICRO_CMPI ) ?                gt | from_ef | to_ef :
    (opcode==`MICRO_TEST ) ?           gs | gt | from_ef | to_ef :
    (opcode==`MICRO_TESTI) ?                gt | from_ef | to_ef : nothing;

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

module instruction_name_by_ascii (
  input wire [`MICRO_W-1:0] opcode,
  output reg [8*5     -1:0] name
);
  assign name =
    (opcode==`MICRO_NOP  ) ? "NOP" :
    (opcode==`MICRO_ADD  ) ? "ADD" :
    (opcode==`MICRO_SUB  ) ? "SUB" :
    (opcode==`MICRO_ADC  ) ? "ADC" :
    (opcode==`MICRO_SBB  ) ? "SBB" :
    (opcode==`MICRO_MUL  ) ? "MUL" :
    (opcode==`MICRO_DIV  ) ? "DIV" :
    (opcode==`MICRO_AND  ) ? "AND" :
    (opcode==`MICRO_OR   ) ? "OR"  :
    (opcode==`MICRO_XOR  ) ? "XOR" :
    (opcode==`MICRO_SLL  ) ? "SLL" :
    (opcode==`MICRO_SRL  ) ? "SRL" :
    (opcode==`MICRO_SRA  ) ? "SRA" :
    (opcode==`MICRO_ADDI ) ? "ADDI" :
    (opcode==`MICRO_SUBI ) ? "SUBI" :
    (opcode==`MICRO_ADCI ) ? "ADCI" :
    (opcode==`MICRO_SBBI ) ? "SBBI" :
    (opcode==`MICRO_MULI ) ? "MULI" :
    (opcode==`MICRO_DIVI ) ? "DIVI" :
    (opcode==`MICRO_ANDI ) ? "ANDI" :
    (opcode==`MICRO_ORI  ) ? "ORI " :
    (opcode==`MICRO_XORI ) ? "XORI" :
    (opcode==`MICRO_SLLI ) ? "SLLI" :
    (opcode==`MICRO_SRLI ) ? "SRLI" :
    (opcode==`MICRO_SRAI ) ? "SRAI" :
    (opcode==`MICRO_LB   ) ? "LB  " :
    (opcode==`MICRO_LW   ) ? "LW  " :
    (opcode==`MICRO_LD   ) ? "LD  " :
    (opcode==`MICRO_LQ   ) ? "LQ  " :
    (opcode==`MICRO_SB   ) ? "SB  " :
    (opcode==`MICRO_SW   ) ? "SW  " :
    (opcode==`MICRO_SD   ) ? "SD  " :
    (opcode==`MICRO_SQ   ) ? "SQ  " :
    (opcode==`MICRO_J    ) ? "J   " :
    (opcode==`MICRO_JR   ) ? "JR  " :
    (opcode==`MICRO_JA   ) ? "JA  " :
    (opcode==`MICRO_JAE  ) ? "JAE " :
    (opcode==`MICRO_JB   ) ? "JB  " :
    (opcode==`MICRO_JBE  ) ? "JBE " :
    (opcode==`MICRO_JC   ) ? "JC  " :
    (opcode==`MICRO_JE   ) ? "JE  " :
    (opcode==`MICRO_JG   ) ? "JG  " :
    (opcode==`MICRO_JGE  ) ? "JGE " :
    (opcode==`MICRO_JL   ) ? "JL  " :
    (opcode==`MICRO_JLE  ) ? "JLE " :
    (opcode==`MICRO_JO   ) ? "JO  " :
    (opcode==`MICRO_JP   ) ? "JP  " :
    (opcode==`MICRO_JS   ) ? "JS  " :
    (opcode==`MICRO_JNE  ) ? "JNE " :
    (opcode==`MICRO_JNP  ) ? "JNP " :
    (opcode==`MICRO_JNS  ) ? "JNS " :
    (opcode==`MICRO_JNO  ) ? "JNO " :
    (opcode==`MICRO_JCX  ) ? "JCX " :
    (opcode==`MICRO_MOV  ) ? "MOV " :
    (opcode==`MICRO_MOVI ) ? "MOVI" :
    (opcode==`MICRO_CMP  ) ? "CMP " :
    (opcode==`MICRO_CMPI ) ? "CMPI" :
    (opcode==`MICRO_TEST ) ? "TEST" :
    (opcode==`MICRO_TESTI) ? "TESTI" : "???";
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
