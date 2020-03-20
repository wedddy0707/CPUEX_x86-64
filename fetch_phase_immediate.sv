`include "common_params.h"
`include "common_params_svfiles.h"

module fetch_phase_immediate (
  input        inst_t inst                    ,
  input        addr_t pc                      ,
  input        fstate state_as_src            ,
  output       fstate state                   ,
  input      miinst_t miinst_as_src[`MQ_N-1:0],
  output     miinst_t miinst       [`MQ_N-1:0],
  input        name_t name_as_src             ,
  output       name_t name                    ,
  input  const_info_t imm_as_src              ,
  output const_info_t imm                     ,
  input  const_info_t disp_as_src             ,
  output const_info_t disp                    ,
  input  logic [ 3:0] rex_as_src              ,
  output logic [ 3:0] rex                     ,
  output logic        valid                   //
);
  integer i;

  // このステートでは変更しないパラメータ
  assign state.dst  =  state_as_src.dst ;
  assign state.grp  =  state_as_src.grp ;
  assign name       =   name_as_src     ;
  assign imm.size   =    imm_as_src.size;
  assign imm.to     =    imm_as_src.to  ;
  assign disp       =   disp_as_src     ;
  assign rex        =    rex_as_src     ;
  
  // validityの判断はこれで十分
  assign valid      =(state.obj==OPCODE_1);
  
  always_comb begin
    imm.cnt   <= imm_as_src.cnt+1;
    state.obj <=(imm_as_src.size > imm_as_src.cnt + 1) ? IMMEDIATE:
                                                         OPCODE_1 ;

    miinst    <= miinst_as_src;
    for (i=0;i<`MQ_N;i=i+1)
    begin
      if (imm_as_src.to[i])
      begin
        case (imm_as_src.cnt)
          2'd0   :miinst[i].imm[`IMM_W-1: 0] <= imm_t'(signed'(inst));
          2'd1   :miinst[i].imm[`IMM_W-1: 8] <= imm_t'(signed'(inst));
          2'd2   :miinst[i].imm[`IMM_W-1:16] <= imm_t'(signed'(inst));
          default:miinst[i].imm[`IMM_W-1:24] <= imm_t'(signed'(inst));
        endcase
      end
    end
  end
endmodule
