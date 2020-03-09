`default_nettype none
`include "common_params.h"
`include "common_params_svfiles.h"

module fetch_phase_modrm (
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
    disp.to[`MQ_LOAD ]    <= 1;
    disp.to[`MQ_STORE]    <= 1;
    miinst [`MQ_LOAD ].op <= MIOP_L;
    miinst [`MQ_LOAD ].d  <= TMP;
    miinst [`MQ_LOAD ].s  <= rega_t'({rex_b,inst[2:0]});
    case (state_as_src.dst)
      DST_RM:
      begin
        miinst[`MQ_ARITH].d  <= TMP;
        miinst[`MQ_ARITH].s  <= TMP;
        miinst[`MQ_ARITH].t  <= rega_t'({rex_r,inst[5:3]});
        miinst[`MQ_STORE].op <= MIOP_S;
        miinst[`MQ_STORE].d  <= TMP;
        miinst[`MQ_STORE].s  <=`rega_t'({rex_b,inst[2:0]});
        case (state_as_src.grp)
          GRP_0: // = どのグループにも属さない
          begin
            case (miinst_as_src[`MQ_ARITH])
              MIOP_TEST :miinst[`MQ_STORE] <= nop;
              MIOP_TESTI:miinst[`MQ_STORE] <= nop;
              MIOP_CMP  :miinst[`MQ_STORE] <= nop;
              MIOP_CMPI :miinst[`MQ_STORE] <= nop;
              default   :begin end
            endcase
          end
          GRP_1:
          begin
            if (inst[5:3]==3'd7) begin
              miinst[`MQ_STORE] <= nop;
            end
            case (inst[5:3])
              3'd0   :begin miinst[`MQ_ARITH].op <=MIOP_ADDI;name<="ADD";end
              3'd1   :begin miinst[`MQ_ARITH].op <=MIOP_ORI ;name<="OR" ;end
              3'd2   :begin miinst[`MQ_ARITH].op <=MIOP_ADCI;name<="ADC";end
              3'd3   :begin miinst[`MQ_ARITH].op <=MIOP_SBBI;name<="SBB";end
              3'd4   :begin miinst[`MQ_ARITH].op <=MIOP_ANDI;name<="AND";end
              3'd5   :begin miinst[`MQ_ARITH].op <=MIOP_SUBI;name<="SUB";end
              3'd6   :begin miinst[`MQ_ARITH].op <=MIOP_XORI;name<="XOR";end
              default:begin miinst[`MQ_ARITH].op <=MIOP_CMPI;name<="CMP";end
            endcase
          end
          GRP_1A:
          begin
            // あとで
          end
          GRP_5:
          begin
             miinst[`MQ_STORE]  <= nop;
            case (inst[5:3])
              3'd2:
              begin
                name              <="CALL";
                miinst[`MQ_RSRV1] <=  addi_on_push(pc);
                miinst[`MQ_RSRV2] <= store_on_push(RIP,pc);
                miinst[`MQ_RSRV3] <=            jr(TMP,pc);
              end
              3'd4:
              begin
                name              <="JMP";
                miinst[`MQ_RSRV3] <=            jr(TMP,pc);
              end
              3'd6:
              begin
                name              <="PUSH";
                miinst[`MQ_RSRV1] <=  addi_on_push(pc);
                miinst[`MQ_RSRV2] <= store_on_push(RIP,pc);
              end
              default:begin end
            endcase
          end
          GRP_11:
          begin
            miinst[`MQ_LOAD ] <= nop;
            case (inst[5:3])
              3'd0   :begin miinst[`MQ_ARITH]<=`MICRO_MOVI;name<="MOV";end
              default:begin end
            endcase
          end
          default:begin end
        endcase
      end
      default: /* = DST_R */
      begin
        miinst[`MQ_ARITH].d <= rega_t'({rex_r,inst[5:3]});
        miinst[`MQ_ARITH].s <= rega_t'({rex_r,inst[5:3]});
        miinst[`MQ_ARITH].t <= TMP                       ;
        case (state_as_src.grp)
          GRP_LEA:
          begin
            miinst[`MQ_LOAD ].op <= MIOP_ADDI;
            miinst[`MQ_ARITH].op <= MIOP_MOV;
          end
          default:begin end
        endcase
      end
    endcase
    
    case (inst[7:6])
      2'b00:// [---]
      begin
        case (inst[2:0])
          3'b101:// disp32のみ
          begin
            disp.size           <= 4;
            miinst[`MQ_SCALE]   <= make_miinst(MIOP_XOR,SCL,SCL,SCL,0,BMD_64,pc);
            miinst[`MQ_LOAD ].s <= SCL;
            miinst[`MQ_STORE].s <= SCL;
            state.obj           <= DISPLACEMENT; 
          end
          3'b100:// SIB後続
          begin
            state.obj <= SIB;
          end
          default:// SIBもDISPLACEMENTも無し
          begin
            state.obj <= (imm_as_src.size==0)? OPCODE_1:IMMEDIATE;
            valid     <= (imm_as_src.size==0);
          end
        endcase
      end
      2'b01:// [---]+disp8
      begin
        disp.size <= 1;
        state.obj <= (inst[2:0]==3'100)? SIB:DISPLACEMENT;
      end
      2'b10:// [---]+disp32
      begin
        disp.size <= 4;
        state.obj <= (inst[2:0]==3'100)? SIB:DISPLACEMENT;
      end
      default: /* = 2'b11 */
      begin
        miinst[`MQ_LOAD ]   <= nop;
        miinst[`MQ_STORE]   <= nop;
        state.obj           <= (imm_as_src.size==0)? OPCODE_1:IMMEDIATE;
        valid               <= (imm_as_src.size==0);

        if (state_as_src.dst==DST_RM) begin
          miinst[`MQ_ARITH].d <= rega_t'({rex_b,inst[2:0]});
          miinst[`MQ_ARITH].s <= rega_t'({rex_b,inst[2:0]});
        end else begin
          if (state_as_src.grp==GRP_LEA) begin
            miinst[`MQ_ARITH].op  <= MIOP_MOVI;
            miinst[`MQ_ARITH].imm <= rega_t'({rex_b,inst[2:0]});
          end else begin
            miinst[`MQ_ARITH].t   <= rega_t'({rex_b,inst[2:0]});
          end
        end
      end
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
endmodule

`default_nettype wire
