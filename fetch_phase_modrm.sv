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
        miinst[`MQ_STORE].s  <= rega_t'({rex_b,inst[2:0]});
        case (state_as_src.grp)
          GRP_0: // = どのグループにも属さない
          begin
            case (miinst_as_src[`MQ_ARITH])
              MIOP_TEST :miinst[`MQ_STORE] <= nop(pc);
              MIOP_TESTI:miinst[`MQ_STORE] <= nop(pc);
              MIOP_CMP  :miinst[`MQ_STORE] <= nop(pc);
              MIOP_CMPI :miinst[`MQ_STORE] <= nop(pc);
              default   :begin end
            endcase
          end
          GRP_1:
          begin
            if (inst[5:3]==3'd7) begin
              miinst[`MQ_STORE] <= nop(pc);
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
          GRP_3:
          begin
            case (inst[5:3])
              default:begin miinst[`MQ_ARITH].op <= MIOP_DIV;name<="IDIV";end
            endcase
          end
          GRP_5:
          begin
             miinst[`MQ_STORE]  <= nop(pc);
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
            miinst[`MQ_LOAD ] <= nop(pc);
            case (inst[5:3])
              3'd0   :begin miinst[`MQ_ARITH]<= MIOP_MOVI;name<="MOV";end
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
        state.obj <= (inst[2:0]==3'b100)? SIB:DISPLACEMENT;
      end
      2'b10:// [---]+disp32
      begin
        disp.size <= 4;
        state.obj <= (inst[2:0]==3'b100)? SIB:DISPLACEMENT;
      end
      default: /* = 2'b11 */
      begin
        miinst[`MQ_LOAD ]   <= nop(pc);
        miinst[`MQ_STORE]   <= nop(pc);
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
endmodule
