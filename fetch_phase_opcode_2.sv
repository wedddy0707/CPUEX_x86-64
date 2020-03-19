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
endmodule

`default_nettype wire
