`include "common_params.h"
`include "common_params_svfiles.h"

module fetch_phase_sib (
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
  imm_t  shift           = imm_t'(inst[7:6]);
  rega_t target_to_scale = miinst_as_src[`MQ_LOAD].s;

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
    miinst[`MQ_SCALE]   <= make_miinst(MIOP_SLLI,SCL,target_to_scale,,shift,BMD_64,pc);
    miinst[`MQ_LOAD ].s <= SCL;
    miinst[`MQ_LOAD ].t <= SCL;
    state.obj <= (disp_as_src.size!=0)? DISPLACEMENT:
                 (imm_as_src.size !=0)? IMMEDIATE   :
                                        OPCODE_1    ;
    valid     <= (disp_as_src.size!=0)? 0:
                 (imm_as_src.size !=0)? 0:
                                        1;
  end
endmodule
