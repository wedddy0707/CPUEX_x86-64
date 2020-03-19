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
    (miinst.op==MIOP_NOP  ) ?                             nothing :
    (miinst.op==MIOP_ADD  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_SUB  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_ADC  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_SBB  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_MUL  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_DIV  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_AND  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_OR   ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_XOR  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_SLL  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_SRL  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_SRA  ) ?   to_gd | gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_ADDI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_SUBI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_ADCI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_SBBI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_MULI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_DIVI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_ANDI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_ORI  ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_XORI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_SLLI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_SRLI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_SRAI ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_L    ) ?   to_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_S    ) ? from_gd | gs      | from_ef | to_ef :
    (miinst.op==MIOP_J    ) ?                             nothing :
    (miinst.op==MIOP_JR   ) ? from_gd                             :
    (miinst.op==MIOP_JA   ) ?                     from_ef         :
    (miinst.op==MIOP_JAE  ) ?                     from_ef         :
    (miinst.op==MIOP_JB   ) ?                     from_ef         :
    (miinst.op==MIOP_JBE  ) ?                     from_ef         :
    (miinst.op==MIOP_JC   ) ?                     from_ef         :
    (miinst.op==MIOP_JE   ) ?                     from_ef         :
    (miinst.op==MIOP_JG   ) ?                     from_ef         :
    (miinst.op==MIOP_JGE  ) ?                     from_ef         :
    (miinst.op==MIOP_JL   ) ?                     from_ef         :
    (miinst.op==MIOP_JLE  ) ?                     from_ef         :
    (miinst.op==MIOP_JO   ) ?                     from_ef         :
    (miinst.op==MIOP_JP   ) ?                     from_ef         :
    (miinst.op==MIOP_JS   ) ?                     from_ef         :
    (miinst.op==MIOP_JNE  ) ?                     from_ef         :
    (miinst.op==MIOP_JNP  ) ?                     from_ef         :
    (miinst.op==MIOP_JNS  ) ?                     from_ef         :
    (miinst.op==MIOP_JNO  ) ?                     from_ef         :
    (miinst.op==MIOP_JCX  ) ?                     from_ef         :
    (miinst.op==MIOP_MOV  ) ?   to_gd |      gt                   :
    (miinst.op==MIOP_MOVI ) ?   to_gd                             :
    (miinst.op==MIOP_CMP  ) ?           gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_CMPI ) ?                gt | from_ef | to_ef :
    (miinst.op==MIOP_TEST ) ?           gs | gt | from_ef | to_ef :
    (miinst.op==MIOP_TESTI) ?                gt | from_ef | to_ef : nothing;

endmodule

module instruction_name_by_ascii (
  input  miinst_t op  ,
  output   name_t name
);
  assign name =
    (op==MIOP_NOP  ) ? "NOP" :
    (op==MIOP_ADD  ) ? "ADD" :
    (op==MIOP_SUB  ) ? "SUB" :
    (op==MIOP_ADC  ) ? "ADC" :
    (op==MIOP_SBB  ) ? "SBB" :
    (op==MIOP_MUL  ) ? "MUL" :
    (op==MIOP_DIV  ) ? "DIV" :
    (op==MIOP_AND  ) ? "AND" :
    (op==MIOP_OR   ) ? "OR"  :
    (op==MIOP_XOR  ) ? "XOR" :
    (op==MIOP_SLL  ) ? "SLL" :
    (op==MIOP_SRL  ) ? "SRL" :
    (op==MIOP_SRA  ) ? "SRA" :
    (op==MIOP_ADDI ) ? "ADDI" :
    (op==MIOP_SUBI ) ? "SUBI" :
    (op==MIOP_ADCI ) ? "ADCI" :
    (op==MIOP_SBBI ) ? "SBBI" :
    (op==MIOP_MULI ) ? "MULI" :
    (op==MIOP_DIVI ) ? "DIVI" :
    (op==MIOP_ANDI ) ? "ANDI" :
    (op==MIOP_ORI  ) ? "ORI " :
    (op==MIOP_XORI ) ? "XORI" :
    (op==MIOP_SLLI ) ? "SLLI" :
    (op==MIOP_SRLI ) ? "SRLI" :
    (op==MIOP_SRAI ) ? "SRAI" :
    (op==MIOP_L    ) ? "LQ  " :
    (op==MIOP_S    ) ? "SB  " :
    (op==MIOP_J    ) ? "J   " :
    (op==MIOP_JR   ) ? "JR  " :
    (op==MIOP_JA   ) ? "JA  " :
    (op==MIOP_JAE  ) ? "JAE " :
    (op==MIOP_JB   ) ? "JB  " :
    (op==MIOP_JBE  ) ? "JBE " :
    (op==MIOP_JC   ) ? "JC  " :
    (op==MIOP_JE   ) ? "JE  " :
    (op==MIOP_JG   ) ? "JG  " :
    (op==MIOP_JGE  ) ? "JGE " :
    (op==MIOP_JL   ) ? "JL  " :
    (op==MIOP_JLE  ) ? "JLE " :
    (op==MIOP_JO   ) ? "JO  " :
    (op==MIOP_JP   ) ? "JP  " :
    (op==MIOP_JS   ) ? "JS  " :
    (op==MIOP_JNE  ) ? "JNE " :
    (op==MIOP_JNP  ) ? "JNP " :
    (op==MIOP_JNS  ) ? "JNS " :
    (op==MIOP_JNO  ) ? "JNO " :
    (op==MIOP_JCX  ) ? "JCX " :
    (op==MIOP_MOV  ) ? "MOV " :
    (op==MIOP_MOVI ) ? "MOVI" :
    (op==MIOP_CMP  ) ? "CMP " :
    (op==MIOP_CMPI ) ? "CMPI" :
    (op==MIOP_TEST ) ? "TEST" :
    (op==MIOP_TESTI) ? "TESTI" : "???";
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
  reg [LATENCY-1:0]tunnel;
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
