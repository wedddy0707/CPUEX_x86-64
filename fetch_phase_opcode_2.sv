`default_nettype none
`include "common_params.h"
`include "common_params_svfiles.h"

module fetch_phase_opcode_2 (
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
  wire rex_w = rex_as_src[3];
  wire rex_r = rex_as_src[2];
  wire rex_x = rex_as_src[1];
  wire rex_b = rex_as_src[0];
  
  // First byte opcode is 0x0f
  always_comb begin
    state  <= state_as_src ;
    miinst <= miinst_as_src;
    name   <= name_as_src  ;
    imm    <= imm_as_src   ;
    disp   <= disp_as_src  ;
    rex    <= rex_as_src   ;
    valid  <=             0;

    casez (inst)
      /*********************
      *     - Jcc
      */
      8'h8?: // Jcc rel16(32)
      begin
        name       <= "JCC";
        miinst [0] <= pre_jcc(inst[3:0],pc);
        disp.to[0] <= 1;
        disp.size  <= 4;
        state.obj  <= DISPLACEMENT;
      end
      /*********************
      *     - Push
      */
      8'hA0:begin end // Push FS 無視
      8'hA8:begin end // Push GS 無視
      /*********************
      *     - Pop
      */
      8'hA1:begin end // Pop FS 無視
      8'hA9:begin end // Pop GS 無視
      /*********************
      *     - Nop
      */
      8'h1f:
      begin
        name  <="NOP";
        state <= make_state(MODRM,DST_RM,GRP_0);
      end
      default:begin end
    endcase
  end
  
  function bmd_t bmd_det (
    input cond_bmd_08,
    input cond_bmd_64
  );
  begin
    bmd_det = (cond_bmd_08) ? BMD_08:
              (cond_bmd_64) ? BMD_64:
                              BMD_32;
  end
  endfunction

  function [3:0] imm_size_det (
    input cond_one_byte,
    input cond_four_byte
  );
  begin
    imm_size_det = (cond_one_byte ) ? 1:
                   (cond_four_byte) ? 4:
                                      0;
  end
  endfunction
  
  function miinst_t make_miinst(
    input miop_t opcode,
    input rega_t d,
    input rega_t s,
    input rega_t t,
    input imm_t  imm.
    input bmd_t  bmd,
    input addr_t pc
  );
  begin
    make_miinst.op  <= opcode;
    make_miinst.d   <= d;
    make_miinst.s   <= s;
    make_miinst.t   <= t;
    make_miinst.imm <= imm;
    make_miinst.bmd <= bmd;
    make_miinst.pc  <= pc;
  end
  endfunction
  
  function miinst_t load_on_pop (input rega_t dest,input addr_t pc);
  begin
    load_on_pop<=make_miinst(MIOP_L,dest,RSP,0,0,BMD_64,pc);
  end
  endfunction

  function miinst_t addi_on_pop(input addr_t pc);
  begin
    addi_on_pop<=make_miinst(MIOP_ADDI,RSP,RSP,`IMM_W(8),BMD_64,pc);
  end
  endfunction
  
  function miinst_t addi_on_push(input addr_t pc);
  begin
    addi_on_pop<=make_miinst(MIOP_ADDI,RSP,RSP,`IMM_W(signed'(-8)),BMD_64,pc);
  end
  endfunction
  
  function miinst_t store_on_push(input rega_t dest,input addr_t pc);
  begin
    load_on_pop<=make_miinst(MIOP_S,dest,RSP,0,0,BMD_64,pc);
  end
  endfunction

  function miinst_t pre_jcc (input [3:0] lower_bits_of_inst,input addr_t pc);
  begin
    case (lower_bits_of_inst)
      4'h0   :pre_jcc <= make_miinst(MIOP_JO ,0,0,0,0,BMD_32,pc);
      4'h1   :pre_jcc <= make_miinst(MIOP_JNO,0,0,0,0,BMD_32,pc);
      4'h2   :pre_jcc <= make_miinst(MIOP_JB ,0,0,0,0,BMD_32,pc);
      4'h3   :pre_jcc <= make_miinst(MIOP_JAE,0,0,0,0,BMD_32,pc);
      4'h4   :pre_jcc <= make_miinst(MIOP_JE ,0,0,0,0,BMD_32,pc);
      4'h5   :pre_jcc <= make_miinst(MIOP_JNE,0,0,0,0,BMD_32,pc);
      4'h6   :pre_jcc <= make_miinst(MIOP_JBE,0,0,0,0,BMD_32,pc);
      4'h7   :pre_jcc <= make_miinst(MIOP_JA ,0,0,0,0,BMD_32,pc);
      4'h8   :pre_jcc <= make_miinst(MIOP_JS ,0,0,0,0,BMD_32,pc);
      4'h9   :pre_jcc <= make_miinst(MIOP_JNS,0,0,0,0,BMD_32,pc);
      4'ha   :pre_jcc <= make_miinst(MIOP_JP ,0,0,0,0,BMD_32,pc);
      4'hb   :pre_jcc <= make_miinst(MIOP_JNP,0,0,0,0,BMD_32,pc);
      4'hc   :pre_jcc <= make_miinst(MIOP_JL ,0,0,0,0,BMD_32,pc);
      4'hd   :pre_jcc <= make_miinst(MIOP_JGE,0,0,0,0,BMD_32,pc);
      4'he   :pre_jcc <= make_miinst(MIOP_JLE,0,0,0,0,BMD_32,pc);
      default:pre_jcc <= make_miinst(MIOP_JG ,0,0,0,0,BMD_32,pc);
    endcase
  end
  endfunction

  function miinst_t jr(input rega_t d,input addr_t pc);
  begin
    jr <= make_miinst(MIOP_JR,d,0,0,0,BMD_32,pc);
  end
  endfunction

  miinst_t nop;
  assign   nop.op  = MIOP_NOP;
  assign   nop.d   =        0;
  assign   nop.s   =        0;
  assign   nop.t   =        0;
  assign   nop.imm =        0;
  assign   nop.bmd =        0;
  assign   nop.pc  =       pc;

  function fstate make_state(
    input fsust_obj  o,
    input fsubst_dst d,
    input fsubst_grp g
  );
  begin
    make_state.obj  <= o;
    make_state.dst  <= d;
    make_state.grp  <= g;
  end
  endfunction
endmodule

`default_nettype wire
