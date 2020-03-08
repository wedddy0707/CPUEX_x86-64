`default_nettype none
`include "common_params.h"

module register_usage_table (
  input  miinst_t miinst,
  output    rut_t rut
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

  assign {rut.d,rut.s,rut.t} = {miinst.d,miinst.s,miinst.t};
  assign {
    rut.from_gd,
    rut.from_fd,
    rut.to_gd,
    rut.to_fd,
    rut.from_gs,
    rut.from_fs,
    rut.from_gt,
    rut.from_ft,
    rut.from_ef,
    rut.to_ef
  } =
    (miinst.opcode==MIOP_NOP  ) ?                             nothing :
    (miinst.opcode==MIOP_ADD  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_SUB  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_ADC  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_SBB  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_MUL  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_DIV  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_AND  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_OR   ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_XOR  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_SLL  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_SRL  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_SRA  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_ADDI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_SUBI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_ADCI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_SBBI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_MULI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_DIVI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_ANDI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_ORI  ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_XORI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_SLLI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_SRLI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_SRAI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_L    ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_S    ) ? from_gd | gs      | from_ef | to_ef :
    (miinst.opcode==MIOP_J    ) ?                             nothing :
    (miinst.opcode==MIOP_JR   ) ? from_gd                             :
    (miinst.opcode==MIOP_JA   ) ?                     from_ef         :
    (miinst.opcode==MIOP_JAE  ) ?                     from_ef         :
    (miinst.opcode==MIOP_JB   ) ?                     from_ef         :
    (miinst.opcode==MIOP_JBE  ) ?                     from_ef         :
    (miinst.opcode==MIOP_JC   ) ?                     from_ef         :
    (miinst.opcode==MIOP_JE   ) ?                     from_ef         :
    (miinst.opcode==MIOP_JG   ) ?                     from_ef         :
    (miinst.opcode==MIOP_JGE  ) ?                     from_ef         :
    (miinst.opcode==MIOP_JL   ) ?                     from_ef         :
    (miinst.opcode==MIOP_JLE  ) ?                     from_ef         :
    (miinst.opcode==MIOP_JO   ) ?                     from_ef         :
    (miinst.opcode==MIOP_JP   ) ?                     from_ef         :
    (miinst.opcode==MIOP_JS   ) ?                     from_ef         :
    (miinst.opcode==MIOP_JNE  ) ?                     from_ef         :
    (miinst.opcode==MIOP_JNP  ) ?                     from_ef         :
    (miinst.opcode==MIOP_JNS  ) ?                     from_ef         :
    (miinst.opcode==MIOP_JNO  ) ?                     from_ef         :
    (miinst.opcode==MIOP_JCX  ) ?                     from_ef         :
    (miinst.opcode==MIOP_MOV  ) ?   to_gd |      gt                   :
    (miinst.opcode==MIOP_MOVI ) ?   to_gd                             :
    (miinst.opcode==MIOP_CMP  ) ?           gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_CMPI ) ?                gt | from_ef | to_ef :
    (miinst.opcode==MIOP_TEST ) ?           gs | gt | from_ef | to_ef :
    (miinst.opcode==MIOP_TESTI) ?                gt | from_ef | to_ef : nothing;

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
  parameter LATENCY   = 3'd1,
  parameter IMMEDIATE = 1'd1
) (
  input  wire        trigger,
  output wire        assertion,
  input  wire        clk,
  input  wire        rstn
);
  reg [ 2:0] timer;

  assign assertion = (IMMEDIATE&trigger)|(|timer);

  always @(posedge clk) begin
    timer <= (~rstn      ) ?       0 :
             (trigger    ) ? LATENCY :
             (timer!=3'd0) ? timer-1 : 0;
  end
endmodule

module trip_assertion #(
  parameter LATENCY = 1
) (
  input  logic trigger ,
  output logic asserion,
  input  logic clk     ,
  input  logic rstn    //
);
  integer i;
  reg     tunnel[LATENCY-1:0];
  assign  assertion = tunnel[LATENCY-1];

  always @(posedge clk) begin
    if (~rstn) begin
      tunnel    <= 0;
    end else begin
      tunnel[0] <= trigger;

      for (i=1;i<LATENCY;i=i+1)
        tunnel[i] <= tunnel[i-1];
    end 
  end
endmodule

`default_nettype wire
