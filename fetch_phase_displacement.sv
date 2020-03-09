`default_nettype none
`include "common_params.h"
`include "common_params_svfiles.h"

module fetch_phase_displacement (
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
  always_comb begin
    // ELSEやDEFAULTを漏れなく書くのは怠すぎるので
    // 先頭にこれを書くことで妥協する
    state  <= state_as_src ;
    miinst <= miinst_as_src;
    name   <= name_as_src  ;
    imm    <= imm_as_src   ;
    disp   <= disp_as_src  ;
    rex    <= rex_as_src   ;
    valid  <=             0;
    
    // 本質はここから
    disp.cnt <= disp_as_src.cnt+1;

    if (disp_as_src.size==disp_as_src.cnt+1) begin
      if (imm_as_src.size==0) begin
        state.obj <= OPCODE_1;
        valid     <= 1;
      end else begin
        state.obj <= IMMEDIATE;
      end         
    end
    
    for (i=0;i<`MQ_N;i=i+1)
    begin
      if (disp_as_src.to[i])
      begin
        case (disp.cnt)
          2'd0   :miinst[i].imm[`IMM_W-1: 0] <= imm_t'(signed'(inst));
          2'd1   :miinst[i].imm[`IMM_W-1: 8] <= imm_t'(signed'(inst));
          2'd2   :miinst[i].imm[`IMM_W-1:16] <= imm_t'(signed'(inst));
          default:miinst[i].imm[`IMM_W-1:24] <= imm_t'(signed'(inst));
        endcase
      end
    end
  end
endmodule

`default_nettype wire
