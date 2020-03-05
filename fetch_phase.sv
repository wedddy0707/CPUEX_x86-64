`default_nettype none
`include "common_params.h"
`include "common_params_in_fetch_phase.sv"


module fetch_phase #(
  parameter LOAD_LATENCY = 1
) (
  input wire [ 8         -1:0] inst, // 毎クロック来る命令
  input wire [`ADDR_W    -1:0] pc_of_this_inst, // と、そのPC
  output reg [`MICRO_W   -1:0] mic_opcode       [`MICRO_Q_N-1:0],
  output reg [`REG_ADDR_W-1:0] mic_reg_addr_d   [`MICRO_Q_N-1:0],
  output reg [`REG_ADDR_W-1:0] mic_reg_addr_s   [`MICRO_Q_N-1:0],
  output reg [`REG_ADDR_W-1:0] mic_reg_addr_t   [`MICRO_Q_N-1:0],
  output reg [`IMM_W     -1:0] mic_immediate    [`MICRO_Q_N-1:0],
  output reg [`BIT_MODE_W-1:0] mic_bit_mode     [`MICRO_Q_N-1:0],
  output reg                   mic_efl_mode     [`MICRO_Q_N-1:0],
  output reg [`ADDR_W    -1:0] mic_pc           [`MICRO_Q_N-1:0],
  output reg                   mic_inst_valid                   ,
  input wire                   stall                            ,
  input wire                   flush                            ,
  input wire                   clk                              ,
  input wire                   rstn
);
  fstate state, state_a_clk_ago;

  enum {
    MODRM_DEST_RM_DEFAULT,
    MODRM_DEST_RM_GRP_1  ,
    MODRM_DEST_RM_GRP_1A ,
    MODRM_DEST_RM_GRP_2  ,
    MODRM_DEST_RM_GRP_3  ,
    MODRM_DEST_RM_GRP_4  ,
    MODRM_DEST_RM_GRP_5  ,
    MODRM_DEST_RM_GRP_6  ,
    MODRM_DEST_RM_GRP_7  ,
    MODRM_DEST_RM_GRP_8  ,
    MODRM_DEST_RM_GRP_9  ,
    MODRM_DEST_RM_GRP_10 ,
    MODRM_DEST_RM_GRP_11
  } substate_modrm_dest_rm;

  enum {
    MODRM_DEST_R_DEFAULT,
    MODRM_DEST_R_LEA
  } substate_modrm_dest_r;

  always @(posedge clk) begin
    state_a_clk_ago <= state;
  end
  
  wire head_inst = // 1命令の先頭のバイトを読むクロックで1になる
    (state==S_OPCODE_1)&(state_a_clk_ago!=S_OPCODE_1);

  reg [8*6-1:0] name; // for debug
  reg [3:0] rex;
  wire      rex_w = rex[3];
  wire      rex_r = rex[2];
  wire      rex_x = rex[1];
  wire      rex_b = rex[0];


  reg [`MICRO_Q_N -1:0] imm_for_whom ;// どの命令が imm  を欲しているのか
  reg [`IMM_W/8   -1:0] imm_byte     ;// byte size of following immediate
  reg                   imm_signex   ;// immediate signed extended
  reg [            1:0] imm_cnt      ;
  reg [`MICRO_Q_N -1:0] disp_for_whom;// どの命令が disp を欲しているのか
  reg [`DISP_W/8  -1:0] disp_byte    ;// byte size of following displacement
  reg                   disp_signex  ;// displacement signed extended
  reg [            1:0] disp_cnt     ;
  
  integer i;

  always @(posedge clk) begin
    if (~rstn) begin
      state <= S_IGNORE_MEANGLESS_ADD_1;
    end else if (flush) begin
      state <= S_OPCODE_1;
    end else if (stall) begin
      state <= state;
    end else begin
      mic_inst_valid <= 0;
      rex            <= 0;

      for (i=0;i<`MICRO_Q_N;i=i+1) begin
        mic_pc[i] <= pc_of_this_inst;
      end

      case (state)
        S_IGNORE_MEANGLESS_ADD_1:begin state<= S_IGNORE_MEANGLESS_ADD_2;end
        S_IGNORE_MEANGLESS_ADD_2:begin state<= S_OPCODE_1;              end
        S_OPCODE_1:
        begin
          /************************************
          * Default settings of micro opcodes
          */
          disp_byte   <= 0;
          disp_signex <= 0;
          disp_cnt    <= 0;
          imm_byte    <= 0;
          imm_signex  <= 0;
          imm_cnt     <= 0;
          substate_modrm_dest_rm <= MODRM_DEST_RM_DEFAULT;
          substate_modrm_dest_r  <= MODRM_DEST_R_DEFAULT ;
          for (i=0;i<`MICRO_Q_N;i=i+1) begin
            mic_opcode      [i] <=`MICRO_NOP  ;
            mic_immediate   [i] <= 0          ;
            mic_bit_mode    [i] <=`BIT_MODE_32;
            mic_efl_mode    [i] <= 0          ;
            mic_reg_addr_d  [i] <= signed'(-1);
            mic_reg_addr_s  [i] <= signed'(-1);
            mic_reg_addr_t  [i] <= signed'(-1);
            imm_for_whom    [i] <= 0          ;
            disp_for_whom   [i] <= 0          ;
          end

          // Priority Encoder
          // - So be careful when you rearrange the sentences.
          casez (inst)
            /**************************
            *       Prefixes
            */
            8'h4?:begin rex<=inst[3:0];            name<="PREFIX";end// REX prefix
            8'h0f:begin rex<=rex;state<=S_OPCODE_2;name<="PREFIX";end// Two-byte opcode escape
            8'b100000??:// Grp1
            begin
              /***************************************
              * case (inst[1:0])
              *   2'd0: XXX r/m8, imm8
              *   2'd1: XXX r/m16(32,64), imm16/32/32
              *   2'd2: Invalid
              *   2'd3: XXX r/m16(32,64), imm8
              * endcase
              */
              name <="PREFIX";
              rex  <= rex    ;
              mic_opcode  [`MICRO_Q_LOAD ] <=(inst[1:0]==2'd0)?`MICRO_LB   :
                                             (rex_w          )?`MICRO_LQ   :
                                                               `MICRO_LD   ;
              mic_opcode  [`MICRO_Q_STORE] <=(inst[1:0]==2'd0)?`MICRO_SB   :
                                             (rex_w          )?`MICRO_SQ   :
                                                               `MICRO_SD   ;
              imm_for_whom[`MICRO_Q_ARITH] <= 1                            ;
              imm_signex                   <= 1                            ;
              imm_byte                     <=(inst[1:0]==2'd1)? 4:1        ;
              mic_bit_mode[`MICRO_Q_ARITH] <=(inst[1:0]==2'd0)?`BIT_MODE_8 :
                                             (rex_w          )?`BIT_MODE_64:
                                                               `BIT_MODE_32;
              state                        <= S_MODRM_DEST_RM              ;
              substate_modrm_dest_rm       <= MODRM_DEST_RM_GRP_1          ;
            end
            8'h8f: // Grp1A, (Pop r/m16(32,64)のみ)
            begin
              /******************************************************
              * if (inst[0]==0) then 8-bit else 16/32/64-bit mode.
              *
              * このグループに属するのはPop r/m16(32,64)のみだが、
              * 統一感を出すためにこのステートでは分からない振り。
              */
              name  <="PREFIX";
              rex   <= rex    ;
              mic_opcode  [`MICRO_Q_LOAD ] <=(inst[1:0]==2'd0)?`MICRO_LB:
                                             (rex_w          )?`MICRO_LQ:
                                                               `MICRO_LD;
              mic_opcode  [`MICRO_Q_STORE] <=(inst[1:0]==2'd0)?`MICRO_SB:
                                             (rex_w          )?`MICRO_SQ:
                                                               `MICRO_SD;
              state                        <= S_MODRM_DEST_RM           ;
              substate_modrm_dest_rm       <= MODRM_DEST_RM_GRP_1A      ;
            end
            8'b1111011?:// Grp3
            begin
              // if (?=0) 8-bit else 16/32/64-bit mode.

            end
            8'hff:// Grp5
            begin
              /****************************************************
              * The instructions in Grp5 don't need `MICRO_Q_STORE
              * instruction.
              */
              name  <="PREFIX";
              rex   <= rex    ;
              mic_opcode  [`MICRO_Q_LOAD ] <=(inst[1:0]==2'd0)?`MICRO_LB:
                                             (rex_w          )?`MICRO_LQ:
                                                               `MICRO_LD;
              state                        <= S_MODRM_DEST_RM           ;
              substate_modrm_dest_rm       <= MODRM_DEST_RM_GRP_5       ;
            end
            8'b1100011?: // Grp11
            begin
              /****************************************************
              * if (inst[0]==0) then 8-bit else 16/32/64-bit mode.
              * The instructions in Grp11 don't need any Load-type
              * instruction.
              */
              name <= "Grp11";
              rex  <= rex;
              mic_opcode  [`MICRO_Q_STORE] <=(inst[1:0]==2'd0)?`MICRO_SB   :
                                             (rex_w          )?`MICRO_SQ   :
                                                               `MICRO_SD   ;
              imm_for_whom[`MICRO_Q_ARITH] <= 1                            ;
              imm_signex                   <= 0                            ;
              imm_byte                     <=(inst[1:0]==2'd1)? 4:1        ;
              mic_bit_mode[`MICRO_Q_ARITH] <=(inst[1:0]==2'd0)?`BIT_MODE_8 :
                                             (rex_w          )?`BIT_MODE_64:
                                                               `BIT_MODE_32;
              state                        <= S_MODRM_DEST_RM              ;
              substate_modrm_dest_rm       <= MODRM_DEST_RM_GRP_11         ;
            end
            
            8'b000?011?: // Pop/Push ES/SS.
            /************************************
            * if (inst[0]==0) then PUSH else POP.
            * if (inst[4]==0) then ES   else SS.
            */
            begin
            end
            8'b000?111?: // Push CS/Push DS/Pop DS
            /************************************
            * if (inst[0]==0) then PUSH else POP.
            * if (inst[4]==0) then CS   else DS.
            * But remember
            *   8'b00001111 represents Two-byte code escape, not POP CS.
            */
            begin
            end
            /*******************************************
            *     - Add, Adc, And, Xor, Or, Sub, etc...
            */
            8'b00??????:
            begin
              /*****************************************************
              * if (inst[0]==0) 8-bit mode  else 16/32/64-bit mode.
              *
              * if      (inst[2]==1) then
              *   XXX AL/AX/EAX/RAX, imm8/16/32/32
              * else if (inst[1]==1) then
              *   XXX r, r/m
              * else                 then
              *   XXX r/m, r
              *
              * 
              */
              rex <= rex;
              mic_bit_mode[`MICRO_Q_ARITH] <=(~inst[0])?`BIT_MODE_8:(rex_w)?`BIT_MODE_64:`BIT_MODE_32;
              mic_efl_mode[`MICRO_Q_ARITH] <= 1;
              case (inst[5:3])
                3'b000 :begin mic_opcode[`MICRO_Q_ARITH]<=(inst[2])?`MICRO_ADDI:`MICRO_ADD;name<="ADD";end
                3'b001 :begin mic_opcode[`MICRO_Q_ARITH]<=(inst[2])?`MICRO_ADCI:`MICRO_ADC;name<="ADC";end
                3'b010 :begin mic_opcode[`MICRO_Q_ARITH]<=(inst[2])?`MICRO_ANDI:`MICRO_AND;name<="AND";end
                3'b011 :begin mic_opcode[`MICRO_Q_ARITH]<=(inst[2])?`MICRO_XORI:`MICRO_XOR;name<="XOR";end
                3'b100 :begin mic_opcode[`MICRO_Q_ARITH]<=(inst[2])?`MICRO_ORI :`MICRO_OR ;name<="OR" ;end
                3'b101 :begin mic_opcode[`MICRO_Q_ARITH]<=(inst[2])?`MICRO_SBBI:`MICRO_SBB;name<="SBB";end
                3'b110 :begin mic_opcode[`MICRO_Q_ARITH]<=(inst[2])?`MICRO_SUBI:`MICRO_SUB;name<="SUB";end
                default:begin mic_opcode[`MICRO_Q_ARITH]<=(inst[2])?`MICRO_CMPI:`MICRO_CMP;name<="CMP";end
              endcase
              if (inst[2]) begin
                mic_reg_addr_d[`MICRO_Q_ARITH]<=`RAX_ADDR     ;
                mic_reg_addr_s[`MICRO_Q_ARITH]<=`RAX_ADDR     ;
                imm_byte                      <=(inst[0])? 4:1;
                imm_for_whom  [`MICRO_Q_ARITH]<= 1            ;
                imm_signex                    <= 1            ;
                state                         <= S_IMMEDIATE  ;
              end else begin
                mic_opcode  [`MICRO_Q_LOAD ]<=(~inst[0])?`MICRO_LB:(rex_w)?`MICRO_LQ:`MICRO_LD;
                if (~inst[1]) begin
                  mic_opcode[`MICRO_Q_STORE]<=(~inst[0])?`MICRO_SB:(rex_w)?`MICRO_SQ:`MICRO_SD;
                  state                     <= S_MODRM_DEST_RM                                ;
                end else begin
                  state                     <= S_MODRM_DEST_R                                 ;
                end
              end
            end
            /**********************************************
            *     - Push/Pop r16(32,64)
            */
            8'b0101????: // Push/Pop r16(32,64)
            begin
              /**********************************************
              * if (inst[3]) then Pop else Push
              *
              * inst[2:0] indicates the address of register.
              */
              // Use Stack Pointer in this instruction
              mic_reg_addr_d[`MICRO_Q_LOAD ]<=`REG_ADDR_W'({rex_b,inst[2:0]});
              mic_reg_addr_s[`MICRO_Q_LOAD ]<=`RSP_ADDR                      ;
              mic_opcode    [`MICRO_Q_ARITH]<=`MICRO_ADDI                    ;
              mic_reg_addr_d[`MICRO_Q_ARITH]<=`RSP_ADDR                      ;
              mic_reg_addr_s[`MICRO_Q_ARITH]<=`RSP_ADDR                      ;
              mic_bit_mode  [`MICRO_Q_ARITH]<=`BIT_MODE_64                   ;
              mic_reg_addr_d[`MICRO_Q_STORE]<=`REG_ADDR_W'({rex_b,inst[2:0]});
              mic_reg_addr_s[`MICRO_Q_STORE]<=`RSP_ADDR                      ;
              mic_inst_valid                <= 1                             ;
              state                         <= S_OPCODE_1                    ;

              if (inst[3]) begin // Pop
                name <= "POP";
                mic_opcode   [`MICRO_Q_LOAD ]<=`MICRO_LQ;
                mic_immediate[`MICRO_Q_ARITH]<=`IMM_W'(signed'( 8));
              end else begin     // Push
                name <= "PUSH";
                mic_immediate[`MICRO_Q_ARITH]<=`IMM_W'(signed'(-8));
                mic_opcode   [`MICRO_Q_STORE]<=`MICRO_SQ           ;
              end
            end
            8'b011010?0: // Push imm8/16/32
            begin
              /***************************************
              * if (inst[1]) then imm8 else imm16/32.
              */
              // Use Stack Pointer in this instruction
              name <= "PUSH";
              mic_opcode    [`MICRO_Q_RSRV1]<=`MICRO_MOVI         ;
              mic_reg_addr_d[`MICRO_Q_RSRV1]<=`TMP_ADDR           ;
              mic_opcode    [`MICRO_Q_RSRV2]<=`MICRO_ADDI         ;
              mic_reg_addr_d[`MICRO_Q_RSRV2]<=`RSP_ADDR           ;
              mic_reg_addr_s[`MICRO_Q_RSRV2]<=`RSP_ADDR           ;
              mic_immediate [`MICRO_Q_RSRV2]<=`IMM_W'(signed'(-8));
              mic_bit_mode  [`MICRO_Q_RSRV2]<=`BIT_MODE_64        ;
              mic_opcode    [`MICRO_Q_RSRV3]<=`MICRO_SB           ;
              mic_reg_addr_d[`MICRO_Q_RSRV3]<=`TMP_ADDR           ;
              mic_reg_addr_s[`MICRO_Q_RSRV3]<=`RSP_ADDR           ;
              imm_for_whom  [`MICRO_Q_RSRV1]<= 1                  ;
              imm_byte                      <=(inst[1])? 1:4;
              imm_signex                    <= 1          ;
              state                         <= S_IMMEDIATE;
            end
            /*********************
            *     - Ret
            */
            8'hc2: // Ret imm16 (Near return)
            begin
              // Use Stack Pointer in this instruction
              name <= "RET";
              mic_opcode    [`MICRO_Q_LOAD ] <=`MICRO_LQ          ;
              mic_reg_addr_d[`MICRO_Q_LOAD ] <=`TMP_ADDR          ;
              mic_reg_addr_s[`MICRO_Q_LOAD ] <=`RSP_ADDR          ;
              mic_opcode    [`MICRO_Q_ARITH] <=`MICRO_ADDI        ;
              mic_reg_addr_d[`MICRO_Q_ARITH] <=`RSP_ADDR          ;
              mic_reg_addr_s[`MICRO_Q_ARITH] <=`RSP_ADDR          ;
              mic_immediate [`MICRO_Q_ARITH] <=`IMM_W'(signed'(8));
              mic_bit_mode  [`MICRO_Q_ARITH] <=`BIT_MODE_64       ;
              mic_opcode    [`MICRO_Q_RSRV1] <=`MICRO_JR          ;
              mic_reg_addr_d[`MICRO_Q_RSRV1] <=`TMP_ADDR          ;
              mic_opcode    [`MICRO_Q_RSRV2] <=`MICRO_ADDI        ;
              mic_bit_mode  [`MICRO_Q_RSRV2] <=`BIT_MODE_32       ;
              mic_reg_addr_d[`MICRO_Q_RSRV2] <=`RSP_ADDR          ;
              mic_reg_addr_s[`MICRO_Q_RSRV2] <=`RSP_ADDR          ;
              imm_for_whom  [`MICRO_Q_RSRV2] <= 1                 ;
              imm_byte                       <= 2                 ;
              state                          <= S_IMMEDIATE       ;
            end
            8'hc3: // Ret (Near return)
            begin
              // Use Stack Pointer in this instruction
              name <= "RET";
              mic_opcode    [`MICRO_Q_LOAD ] <=`MICRO_LQ          ;
              mic_reg_addr_d[`MICRO_Q_LOAD ] <=`TMP_ADDR          ;
              mic_reg_addr_s[`MICRO_Q_LOAD ] <=`RSP_ADDR          ;
              mic_opcode    [`MICRO_Q_ARITH] <=`MICRO_ADDI        ;
              mic_reg_addr_d[`MICRO_Q_ARITH] <=`RSP_ADDR          ;
              mic_reg_addr_s[`MICRO_Q_ARITH] <=`RSP_ADDR          ;
              mic_immediate [`MICRO_Q_ARITH] <=`IMM_W'(signed'(8));
              mic_bit_mode  [`MICRO_Q_ARITH] <=`BIT_MODE_64       ;
              mic_opcode    [`MICRO_Q_RSRV1] <=`MICRO_JR          ;
              mic_reg_addr_d[`MICRO_Q_RSRV1] <=`TMP_ADDR          ;
              mic_inst_valid                 <= 1                 ;
              state                          <= S_OPCODE_1        ;
            end
            8'hca:begin end // Ret imm16 (Far  return) 無視
            8'hcb:begin end // Ret       (Far  return) 無視
            /*********************
            *     - Call
            *       - Grp5あり
            */
            8'he8: // Call rel16(32)
            begin
              // Use Stack Pointer in this instruction
              name <= "CALL";
              mic_opcode    [`MICRO_Q_RSRV1] <=`MICRO_MOVI               ;
              mic_reg_addr_d[`MICRO_Q_RSRV1] <=`TMP_ADDR                 ;
              mic_immediate [`MICRO_Q_RSRV1] <=`REG_W'(pc_of_this_inst)+5;
              mic_opcode    [`MICRO_Q_RSRV2] <=`MICRO_ADDI               ;
              mic_reg_addr_d[`MICRO_Q_RSRV2] <=`RSP_ADDR                 ;
              mic_reg_addr_s[`MICRO_Q_RSRV2] <=`RSP_ADDR                 ;
              mic_immediate [`MICRO_Q_RSRV2] <=`IMM_W'(signed'(-8))      ;
              mic_bit_mode  [`MICRO_Q_RSRV2] <=`BIT_MODE_64              ;
              mic_opcode    [`MICRO_Q_RSRV3] <=`MICRO_SQ                 ;
              mic_reg_addr_d[`MICRO_Q_RSRV3] <=`TMP_ADDR                 ;
              mic_reg_addr_s[`MICRO_Q_RSRV3] <=`RSP_ADDR                 ;
              mic_opcode    [`MICRO_Q_RSRV4] <=`MICRO_J                  ;
              disp_for_whom [`MICRO_Q_RSRV4] <= 1                        ;
              disp_byte                      <= 4                        ;
              rex                            <= rex                      ;
              state                          <= S_DISPLACEMENT           ;
            end
            /*********************
            *     - JMP
            */
            8'heb:
            begin
              name <= "JMP";
              mic_opcode   [`MICRO_Q_RSRV1] <=`MICRO_J;
              disp_for_whom[`MICRO_Q_RSRV1] <= 1;
              disp_byte                     <= 1;
              state                         <= S_DISPLACEMENT;
            end
            8'h9A:begin end // Call ptr16:16(32) 無視
            /*********************
            *     - Mov
            *     - Lea
            */
            8'b100010??:
            begin
              name <="MOV";
              rex  <= rex ;
              mic_opcode  [`MICRO_Q_ARITH]<=`MICRO_MOV;
              mic_bit_mode[`MICRO_Q_ARITH]<=(~inst[0])?`BIT_MODE_8:(rex_w)?`BIT_MODE_64:`BIT_MODE_32;
              mic_opcode  [`MICRO_Q_LOAD ]<=(~inst[0])?  `MICRO_LB:(rex_w)?   `MICRO_LQ:   `MICRO_LD;
              if (~inst[1]) begin
                mic_opcode[`MICRO_Q_STORE]<=(~inst[0])?  `MICRO_SB:(rex_w)?   `MICRO_SQ:   `MICRO_SD;
                state                     <= S_MODRM_DEST_RM;
              end else begin
                state                     <= S_MODRM_DEST_R ;
              end
            end
            8'h8c:begin end // Mov 0-extended 16-bit Sreg to r16/r32/r64/m16 無視
            8'h8d: // Lea r16(32,64) m
            begin
              /******************************************************
              * Lea can be regarded as a special type of Mov r,r/m
              * because it can be realized by
              *   - replacing a Load-type instruction with ADDI
              * of Mov (see below).
              *
              * Mov:
              *   Load  $temp $r/m [imm]
              *   Mov   $r    $temp
              *
              * Lea:
              *   Addi  $temp $r/m [imm]
              *   Mov   $r    $temp
              */
              name <="LEA";
              rex  <= rex ;
              mic_opcode  [`MICRO_Q_LOAD ]<=`MICRO_ADDI      ;// ADDI comes in pretending to be "Load".
              mic_bit_mode[`MICRO_Q_LOAD ]<=`BIT_MODE_32     ;
              mic_opcode  [`MICRO_Q_ARITH]<=`MICRO_MOV       ;
              mic_bit_mode[`MICRO_Q_ARITH]<=`BIT_MODE_32     ;
              state                       <= S_MODRM_DEST_R  ;
              substate_modrm_dest_r       <= MODRM_DEST_R_LEA;
            end
            8'h8e:begin end // Mov lower 16 bits of r/m16(64) to Sreg 無視
            8'ha0:begin end // Mov byte at (seg:offset) to AL 無視
            8'ha1:begin end // Mov byte at (offset) to AX 無視
            8'ha2:begin end // Mov AL to (seg:offset) 無視
            8'ha3:begin end // Mov AX/EAX/RAX to (seg:offset)/(seg:offset)/(offset) 無視
            8'b1011????: // Mov imm8/16/32/32 to r8/16/32/64
            /***********************************************
            * if (inst[3]==0) then 8-bit else 16/32/64-bit.
            */
            begin
              name <= "MOV";
              mic_opcode    [`MICRO_Q_ARITH] <=`MICRO_MOVI                    ;
              mic_reg_addr_d[`MICRO_Q_ARITH] <=`REG_ADDR_W'({rex_b,inst[2:0]});
              imm_for_whom  [`MICRO_Q_ARITH] <= 1                             ;
              state                          <= S_IMMEDIATE                   ;
              if (inst[3]==0) begin
                mic_bit_mode[`MICRO_Q_ARITH] <=`BIT_MODE_8                    ;
                imm_byte                     <= 1                             ;
              end else begin
                mic_bit_mode[`MICRO_Q_ARITH] <=rex_w?`BIT_MODE_64:`BIT_MODE_32;
                imm_byte                     <= 4                             ;
              end
            end
            /*********************
            *     - Jcc
            */
            8'h7?: // Jcc rel8
            begin
              name <= "JCC";
              case (inst[3:0])
                4'h0   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JO ;
                4'h1   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JNO;
                4'h2   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JB ;
                4'h3   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JAE;
                4'h4   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JE ;
                4'h5   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JNE;
                4'h6   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JBE;
                4'h7   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JA ;
                4'h8   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JS ;
                4'h9   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JNS;
                4'ha   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JP ;
                4'hb   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JNP;
                4'hc   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JL ;
                4'hd   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JGE;
                4'he   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JLE;
                default:mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JG ;
              endcase
              disp_for_whom[`MICRO_Q_RSRV1] <= 1;
              disp_byte                     <= 1;
              disp_signex                   <= 1;
              state                         <= S_DISPLACEMENT;
            end
            8'he3: // JCX rel8 (CX/ECX/RCX = 0)
            begin
              name <= "JCX";
              mic_opcode   [`MICRO_Q_RSRV1] <=`MICRO_JCX;
              mic_bit_mode [`MICRO_Q_RSRV1] <= rex_w ? `BIT_MODE_64:`BIT_MODE_32;
              disp_for_whom[`MICRO_Q_RSRV1] <= 1;
              disp_byte                     <= 1;
              disp_signex                   <= 1;
              state                         <= S_DISPLACEMENT;
            end
            /******************************
            *     - Test : Logical Compare
            */
            8'b1000010?: // if (?=0) then TEST r/m8 r8 else TEST r/m16(32,64) r16(32,64)
            begin
              name <= "TEST";
              rex  <= rex   ;
              mic_opcode  [`MICRO_Q_LOAD ]<=(~inst[0])?  `MICRO_LB:(rex_w)?   `MICRO_LQ:   `MICRO_LD;
              mic_opcode  [`MICRO_Q_ARITH]<=(~inst[0])?`BIT_MODE_8:(rex_w)?`BIT_MODE_64:`BIT_MODE_32;
              mic_opcode  [`MICRO_Q_ARITH]<=`MICRO_TEST                                             ;
              mic_efl_mode[`MICRO_Q_ARITH]<= 1;
              state                       <= S_MODRM_DEST_RM                                        ;
            end
            8'b1010100?: // if (?=0) then TEST AL,imm8 else TEST AX/EAX/RAX,imm16/32/32
            begin
              name <= "TEST";
              rex  <= rex   ;
              mic_opcode  [`MICRO_Q_ARITH]<=`MICRO_TESTI                                            ;
              mic_opcode  [`MICRO_Q_ARITH]<=(~inst[0])?`BIT_MODE_8:(rex_w)?`BIT_MODE_64:`BIT_MODE_32;
              imm_byte                    <=(~inst[0])? 1:4;
              imm_for_whom[`MICRO_Q_ARITH]<= 1             ;
              mic_efl_mode[`MICRO_Q_ARITH]<= 1             ;
              state                       <= S_IMMEDIATE   ;
            end
            default:begin end
          endcase
        end
        S_OPCODE_2:
        begin
          // First byte opcode is 0x0f
          casez (inst)
            /*********************
            *     - Jcc
            */
            8'h8?: // Jcc rel16(32)
            begin
              name <= "JCC";
              case (inst[3:0])
                4'h0   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JO ;
                4'h1   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JNO;
                4'h2   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JB ;
                4'h3   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JAE;
                4'h4   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JE ;
                4'h5   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JNE;
                4'h6   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JBE;
                4'h7   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JA ;
                4'h8   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JS ;
                4'h9   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JNS;
                4'ha   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JP ;
                4'hb   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JNP;
                4'hc   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JL ;
                4'hd   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JGE;
                4'he   :mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JLE;
                default:mic_opcode[`MICRO_Q_RSRV1] <=`MICRO_JG ;
              endcase
              disp_for_whom[`MICRO_Q_RSRV1] <= 1;
              disp_byte                     <= 4;
              disp_signex                   <= 1;
              state                         <= S_DISPLACEMENT;
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
              name  <= "NOP";
              state <= S_MODRM_DEST_RM;
            end
            default:begin end
          endcase
        end
        S_MODRM_DEST_RM:
        begin
          /****************************************************************
          * デフォルトでは
          *   LOAD  $temp, [address]
          *   XXX   $temp, $temp, $r
          *   STORE $temp, [address]
          * という命令列.
          * しかし,
          * GrpやModによって変更することがあるので注意.
          *
          */
          mic_reg_addr_d[`MICRO_Q_LOAD ] <=`TMP_ADDR                      ;
          mic_reg_addr_s[`MICRO_Q_LOAD ] <=`REG_ADDR_W'({rex_b,inst[2:0]});
          mic_reg_addr_d[`MICRO_Q_ARITH] <=`TMP_ADDR                      ;
          mic_reg_addr_s[`MICRO_Q_ARITH] <=`TMP_ADDR                      ;
          mic_reg_addr_t[`MICRO_Q_ARITH] <=`REG_ADDR_W'({rex_r,inst[5:3]});
          mic_reg_addr_d[`MICRO_Q_STORE] <=`TMP_ADDR                      ;
          mic_reg_addr_s[`MICRO_Q_STORE] <=`REG_ADDR_W'({rex_b,inst[2:0]});

          disp_for_whom [`MICRO_Q_LOAD ] <= 1;
          disp_for_whom [`MICRO_Q_STORE] <= 1;
          
          case (substate_modrm_dest_rm)
            MODRM_DEST_RM_GRP_1: // inst[5:3] indicates some instruction.
            begin
              /***********************************************************
              * The instructions in Grp1 takes an immediate value.
              * They need both Load-type and Store-type instructions.
              * Except CMP.
              */
              case (inst[5:3])
                3'd0   :begin mic_opcode[`MICRO_Q_ARITH]<=`MICRO_ADDI;name<="ADD";end
                3'd1   :begin mic_opcode[`MICRO_Q_ARITH]<=`MICRO_ORI ;name<="OR" ;end
                3'd2   :begin mic_opcode[`MICRO_Q_ARITH]<=`MICRO_ADCI;name<="ADC";end
                3'd3   :begin mic_opcode[`MICRO_Q_ARITH]<=`MICRO_SBBI;name<="SBB";end
                3'd4   :begin mic_opcode[`MICRO_Q_ARITH]<=`MICRO_ANDI;name<="AND";end
                3'd5   :begin mic_opcode[`MICRO_Q_ARITH]<=`MICRO_SUBI;name<="SUB";end
                3'd6   :begin mic_opcode[`MICRO_Q_ARITH]<=`MICRO_XORI;name<="XOR";end
                default:begin mic_opcode[`MICRO_Q_ARITH]<=`MICRO_CMPI;name<="CMP";mic_opcode[`MICRO_Q_STORE]<=`MICRO_NOP;end
              endcase
            end
            MODRM_DEST_RM_GRP_1A: // inst[5:3] indicates some instruction.
            begin
              // Use Stack Pointer in this instruction
              case (inst[5:3])
                3'd0   :begin                                         name<="POP";
                  mic_opcode    [`MICRO_Q_RSRV1]<=`MICRO_ADDI        ;
                  mic_reg_addr_d[`MICRO_Q_RSRV1]<=`RSP_ADDR          ;
                  mic_reg_addr_s[`MICRO_Q_RSRV1]<=`RSP_ADDR          ;
                  mic_bit_mode  [`MICRO_Q_RSRV1]<=`BIT_MODE_64       ;
                  mic_immediate [`MICRO_Q_RSRV1]<=`IMM_W'(signed'(8));
                end
                default:begin /* Invalid */                           name<="!!!";end
              endcase
            end
            MODRM_DEST_RM_GRP_5: // inst[5:3] indicates some instruction.
            begin
              // Use Stack Pointer in this instruction
              // RSRV1とRSRV2でPUSH(RIP)
              mic_opcode    [`MICRO_Q_RSRV1]<=`MICRO_ADDI         ;
              mic_reg_addr_d[`MICRO_Q_RSRV1]<=`RSP_ADDR           ;
              mic_reg_addr_s[`MICRO_Q_RSRV1]<=`RSP_ADDR           ;
              mic_immediate [`MICRO_Q_RSRV1]<=`IMM_W'(signed'(-8));
              mic_bit_mode  [`MICRO_Q_RSRV1]<=`BIT_MODE_64        ;
              mic_opcode    [`MICRO_Q_RSRV2]<=`MICRO_SQ           ;
              mic_reg_addr_d[`MICRO_Q_RSRV2]<=`RIP_ADDR           ;
              mic_reg_addr_s[`MICRO_Q_RSRV2]<=`RSP_ADDR           ;
              case (inst[5:3])
                3'd2   :begin                                         name<="CALL";
                  mic_opcode    [`MICRO_Q_RSRV3]<=`MICRO_JR;
                  mic_reg_addr_d[`MICRO_Q_RSRV3]<=`TMP_ADDR;
                end
                3'd6   :begin                                         name<="PUSH";
                end
                default:begin                                         name<="!!!";end
              endcase
            end
            MODRM_DEST_RM_GRP_11: // inst[5:3] indicates some instruction.
            begin
              /***********************************************************
              * The instructions in Grp11 takes an immediate value.
              * They need Store-type, but not Load-type instructions.
              *
              */
              case (inst[5:3])
                3'd0   :begin mic_opcode[`MICRO_Q_ARITH]<=`MICRO_MOVI;name<="MOV";end
                default:begin                                         name<="!!!";end
              endcase
            end
            default:// inst[5:3] indicates the address of register.
            begin
              /***********************************************************
              * We can expect that
              * mic_opcode[`MICRO_Q_ARITH] was set a clk ago.
              */
            end
          endcase

          case (inst[7:6])
            2'b00: begin // [---]
              case (inst[2:0])
                3'b101:// disp32のみ
                begin
                  // Load, Storeへのsレジスタはゼロにする
                  // Xor $scl $scl $scl で実現
                  disp_byte                      <= 4;
                  mic_opcode    [`MICRO_Q_SCALE] <=`MICRO_XOR;
                  mic_reg_addr_d[`MICRO_Q_SCALE] <=`SCL_ADDR;
                  mic_reg_addr_s[`MICRO_Q_SCALE] <=`SCL_ADDR;
                  mic_reg_addr_t[`MICRO_Q_SCALE] <=`SCL_ADDR;
                  mic_reg_addr_s[`MICRO_Q_LOAD ] <=`SCL_ADDR;
                  mic_reg_addr_s[`MICRO_Q_STORE] <=`SCL_ADDR;
                  state <= S_DISPLACEMENT; 
                end
                3'b100 :// SIB が後続する
                begin
                  state <= S_SIB_DEST_RM;
                end
                default:// SIBもDISPLACEMENTも無し
                begin
                  if (imm_byte==0) begin
                    state         <= S_OPCODE_1;
                    mic_inst_valid<= 1;
                  end else begin
                    state         <= S_IMMEDIATE;
                  end
                end
              endcase
            end
            2'b01: begin // [---] + disp8
              disp_byte <= 1;
              case (inst[2:0])
                3'b100 :begin state <= S_SIB_DEST_RM;  end
                default:begin state <= S_DISPLACEMENT; end
              endcase
            end
            2'b10: begin // [---] + disp32
              disp_byte <= 4;
              case (inst[2:0])
                3'b100 :begin state <= S_SIB_DEST_RM;  end
                default:begin state <= S_DISPLACEMENT; end
              endcase
            end
            default: /* = 2'b11 */ begin
              /************************************************************
              * メモリアクセス無しの命令であることが判明するので
              * Load, Store を Nop に置き換え、
              * メインとなる命令のオペランドを指定しなおす
              */
              mic_opcode    [`MICRO_Q_LOAD ] <= `MICRO_NOP;
              mic_opcode    [`MICRO_Q_STORE] <= `MICRO_NOP;
              mic_reg_addr_d[`MICRO_Q_ARITH] <= `REG_ADDR_W'({rex_b,inst[2:0]});
              mic_reg_addr_s[`MICRO_Q_ARITH] <= `REG_ADDR_W'({rex_b,inst[2:0]});
              
              if (imm_byte==0) begin
                state         <= S_OPCODE_1;
                mic_inst_valid<= 1;
              end else begin
                state         <= S_IMMEDIATE;
              end
            end
          endcase
        end
        S_SIB_DEST_RM:
        begin
          mic_opcode    [`MICRO_Q_SCALE]<=`MICRO_SLLI                   ;
          mic_reg_addr_d[`MICRO_Q_SCALE]<=`SCL_ADDR                     ;
          mic_reg_addr_s[`MICRO_Q_SCALE]<= mic_reg_addr_s[`MICRO_Q_LOAD];
          mic_immediate [`MICRO_Q_SCALE]<=`IMM_W'(inst[7:6])            ;
          mic_bit_mode  [`MICRO_Q_SCALE]<=`BIT_MODE_64                  ;
          mic_reg_addr_s[`MICRO_Q_LOAD ]<=`SCL_ADDR                     ;
          mic_reg_addr_s[`MICRO_Q_STORE]<=`SCL_ADDR                     ;
          
          if (disp_byte!=0) begin
            state <= S_DISPLACEMENT;
          end else if (imm_byte!=0) begin
            state <= S_IMMEDIATE;
          end else begin
            state <= S_OPCODE_1;
            mic_inst_valid <= 1;
          end
        end
        S_MODRM_DEST_R:
        begin
          mic_reg_addr_d[`MICRO_Q_LOAD ]<=`TMP_ADDR                      ;
          mic_reg_addr_s[`MICRO_Q_LOAD ]<=`REG_ADDR_W'({rex_b,inst[2:0]});
          mic_reg_addr_d[`MICRO_Q_ARITH]<=`REG_ADDR_W'({rex_r,inst[5:3]});
          mic_reg_addr_s[`MICRO_Q_ARITH]<=`REG_ADDR_W'({rex_r,inst[5:3]});
          mic_reg_addr_t[`MICRO_Q_ARITH]<=`TMP_ADDR                      ;
          
          disp_for_whom [`MICRO_Q_LOAD ]<= 1;
          
          case (inst[7:6])
            2'b00: begin // [---]
              case (inst[2:0])
                3'b101:// disp32 のみ
                begin
                  // Loadへのsレジスタはゼロにする
                  // Xor $scl $scl $scl で実現
                  disp_byte                      <= 4;
                  mic_opcode    [`MICRO_Q_SCALE] <=`MICRO_XOR;
                  mic_reg_addr_d[`MICRO_Q_SCALE] <=`SCL_ADDR;
                  mic_reg_addr_s[`MICRO_Q_SCALE] <=`SCL_ADDR;
                  mic_reg_addr_t[`MICRO_Q_SCALE] <=`SCL_ADDR;
                  mic_reg_addr_s[`MICRO_Q_LOAD ] <=`SCL_ADDR;
                  state                          <= S_DISPLACEMENT;
                end
                3'b100 :// SIBが後続
                begin
                  state <= S_SIB_DEST_R;
                end
                default:// SIBもDisplacementも無し
                begin
                  if (imm_byte==0) begin
                    state         <= S_OPCODE_1;
                    mic_inst_valid<= 1;
                  end else begin
                    state         <= S_IMMEDIATE;
                  end
                end
              endcase
            end
            2'b01: begin // [---] + disp8
              disp_byte <= 1;
              case (inst[2:0])
                3'b100 :begin state <= S_SIB_DEST_R;   end
                default:begin state <= S_DISPLACEMENT; end
              endcase
            end
            2'b10: begin // [---] + disp32
              disp_byte <= 4;
              case (inst[2:0])
                3'b100 :begin state <= S_SIB_DEST_R;   end
                default:begin state <= S_DISPLACEMENT; end
              endcase
            end
            default: /* = 2'b11 */ begin
              mic_opcode    [`MICRO_Q_LOAD ] <=`MICRO_NOP;
              case (substate_modrm_dest_r)
                MODRM_DEST_R_LEA: begin
                  mic_opcode    [`MICRO_Q_ARITH]<=`MICRO_MOVI;
                  mic_immediate [`MICRO_Q_ARITH]<=`IMM_W'({rex_b,inst[2:0]});
                end
                default: begin
                  mic_reg_addr_t[`MICRO_Q_ARITH]<=`REG_ADDR_W'({rex_b,inst[2:0]});
                end
              endcase
              if (imm_byte==0) begin
                state         <= S_OPCODE_1;
                mic_inst_valid<= 1;
              end else begin
                state         <= S_IMMEDIATE;
              end
            end
          endcase
        end
        S_SIB_DEST_R:
        begin
          mic_opcode    [`MICRO_Q_SCALE]<=`MICRO_SLLI                   ;
          mic_reg_addr_d[`MICRO_Q_SCALE]<=`SCL_ADDR                     ;
          mic_reg_addr_s[`MICRO_Q_SCALE]<= mic_reg_addr_s[`MICRO_Q_LOAD];
          mic_immediate [`MICRO_Q_SCALE]<=`IMM_W'(inst[7:6])            ;
          mic_bit_mode  [`MICRO_Q_SCALE]<=`BIT_MODE_64                  ;
          mic_reg_addr_s[`MICRO_Q_LOAD ]<=`SCL_ADDR                     ;
          if (disp_byte!=0) begin
            state <= S_DISPLACEMENT;
          end else if (imm_byte!=0) begin
            state <= S_IMMEDIATE;
          end else begin
            state <= S_OPCODE_1;
            mic_inst_valid <= 1;
          end
        end

        S_IMMEDIATE:
        begin
          imm_cnt <= imm_cnt+1;

          if (imm_byte==imm_cnt+1) begin
            state          <= S_OPCODE_1;
            mic_inst_valid <= 1;
          end
          
          for (i=0;i<`MICRO_Q_N;i=i+1)
          begin
            if (imm_for_whom[i])
            begin
              case (imm_cnt)
                2'd0: begin
                  if (imm_signex) begin
                    mic_immediate[i][`IMM_W-1: 0]<=`IMM_W'(signed'(inst));
                  end else begin
                    mic_immediate[i][`IMM_W-1: 0]<=`IMM_W'(inst);
                  end
                end
                2'd1: begin
                  if (imm_signex) begin
                    mic_immediate[i][`IMM_W-1: 8]<=(`IMM_W-8)'(signed'(inst));
                  end else begin
                    mic_immediate[i][`IMM_W-1: 8]<=(`IMM_W-8)'(inst);
                  end
                end
                2'd2: begin
                  if (imm_signex) begin
                    mic_immediate[i][`IMM_W-1:16]<=(`IMM_W-16)'(signed'(inst));
                  end else begin
                    mic_immediate[i][`IMM_W-1:16]<=(`IMM_W-16)'(inst);
                  end
                end
                default: begin
                  if (imm_signex) begin
                    mic_immediate[i][`IMM_W-1:24] <= (`IMM_W-24)'(signed'(inst));
                  end else begin
                    mic_immediate[i][`IMM_W-1:24] <= (`IMM_W-24)'(inst);
                  end
                end
              endcase
            end
          end
        end
        S_DISPLACEMENT:
        begin
          disp_cnt <= disp_cnt+1;

          if (disp_byte==disp_cnt+1) begin
            if (imm_byte==0) begin
              state <= S_OPCODE_1;
              mic_inst_valid <= 1;
            end else begin
              state <= S_IMMEDIATE;
            end         
          end
          
          for (i=0;i<`MICRO_Q_N;i=i+1)
          begin
            if (disp_for_whom[i])
            begin
              case (disp_cnt)
                2'd0: begin
                  if (1|disp_signex) begin
                    mic_immediate[i][`DISP_W-1: 0]<=`DISP_W'(signed'(inst));
                  end else begin
                    mic_immediate[i][`DISP_W-1: 0]<=`DISP_W'(inst);
                  end
                end
                2'd1: begin
                  if (1|disp_signex) begin
                    mic_immediate[i][`DISP_W-1: 8]<=(`DISP_W-8)'(signed'(inst));
                  end else begin
                    mic_immediate[i][`DISP_W-1: 8]<=(`DISP_W-8)'(inst);
                  end
                end
                2'd2: begin
                  if (1|disp_signex) begin
                    mic_immediate[i][`DISP_W-1:16]<=(`DISP_W-16)'(signed'(inst));
                  end else begin
                    mic_immediate[i][`DISP_W-1:16]<=(`DISP_W-16)'(inst);
                  end
                end
                default: begin
                  if (1|disp_signex) begin
                    mic_immediate[i][`DISP_W-1:24]<=(`DISP_W-24)'(signed'(inst));
                  end else begin
                    mic_immediate[i][`DISP_W-1:24]<=(`DISP_W-24)'(inst);
                  end
                end
              endcase
            end
          end
        end
        default:
        begin
          state <= S_OPCODE_1;
        end
      endcase
    end
  end
endmodule
`default_nettype wire
