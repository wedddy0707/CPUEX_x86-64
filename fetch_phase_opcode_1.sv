`default_nettype none
`include "common_params.h"
`include "common_params_in_fetch_phase.h"

module fetch_phase_opcode_1 (
  input wire [ 8         -1:0] inst                 , // 毎クロック来る命令
  input wire [`ADDR_W    -1:0] pc_of_this_inst      , // と、そのPC
  output fstate                state                ,
  output reg [`NAME_W    -1:0] name                 ,
  output reg [`MICRO_W   -1:0] opcode    [`MQ_N-1:0],
  output reg [`REG_ADDR_W-1:0] reg_addr_d[`MQ_N-1:0],
  output reg [`REG_ADDR_W-1:0] reg_addr_s[`MQ_N-1:0],
  output reg [`REG_ADDR_W-1:0] reg_addr_t[`MQ_N-1:0],
  output reg [`IMM_W     -1:0] immediate [`MQ_N-1:0],
  output reg [`BIT_MD_W  -1:0] bit_mode  [`MQ_N-1:0],
  output reg                   efl_mode  [`MQ_N-1:0],
  output reg [`ADDR_W    -1:0] pc        [`MQ_N-1:0],
  output reg [`IMM_W/8   -1:0] imm_byte             ,
  output reg [`MQ_N -1:0] imm_to                    ,
  output reg [`DISP_W/8  -1:0] disp_byte            ,
  output reg [`MQ_N -1:0] disp_to                   ,
  output reg                   valid                     //
);

  localparam IMM_ON_POP  = `IMM_W'(signed'( 8)); // RSPをどれくらいずらすか
  localparam IMM_ON_PUSH = `IMM_W'(signed'(-8)); // RSPをどれくらいずらすか

  always_comb begin
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
        opcode  [`MQ_LOAD ]<=(inst[1:0]==2'd0)?`MICRO_LB:(rex_w)?`MICRO_LQ:`MICRO_LD;
        opcode  [`MQ_STORE]<=(inst[1:0]==2'd0)?`MICRO_SB:(rex_w)?`MICRO_SQ:`MICRO_SD;
        imm_to  [`MQ_ARITH]<= 1;
        imm_byte           <=(inst[1:0]==2'd1)? 4:1;
        bit_mode[`MQ_ARITH]<=(inst[1:0]==2'd0)?`BIT_MD_8 :
                                   (rex_w         )?`BIT_MD_64:
                                                    `BIT_MD_32;
        state                   <= S_MODRM_DEST_RM         ;
        substate_modrm_dest_rm  <= MODRM_DEST_RM_GRP_1     ;
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
        opcode  [`MQ_LOAD ]<=(inst[1:0]==2'd0)?`MICRO_LB:
                                  (rex_w          )?`MICRO_LQ:
                                                    `MICRO_LD;
        opcode  [`MQ_STORE]<=(inst[1:0]==2'd0)?`MICRO_SB:
                                  (rex_w          )?`MICRO_SQ:
                                                    `MICRO_SD;
        state                   <= S_MODRM_DEST_RM           ;
        substate_modrm_dest_rm  <= MODRM_DEST_RM_GRP_1A      ;
      end
      8'b1111011?:// Grp3
      begin
        // if (?=0) 8-bit else 16/32/64-bit mode.

      end
      8'hff:// Grp5
      begin
        /****************************************************
        * The instructions in Grp5 don't need `MQ_STORE
        * instruction.
        */
        name  <="PREFIX";
        rex   <= rex    ;
        opcode  [`MQ_LOAD ] <=(inst[1:0]==2'd0)?`MICRO_LB:
                                   (rex_w          )?`MICRO_LQ:
                                                     `MICRO_LD;
        state                    <= S_MODRM_DEST_RM           ;
        substate_modrm_dest_rm   <= MODRM_DEST_RM_GRP_5       ;
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
        opcode  [`MQ_STORE] <=(inst[1:0]==2'd0)?`MICRO_SB   :
                                   (rex_w          )?`MICRO_SQ   :
                                                     `MICRO_SD   ;
        imm_to[`MQ_ARITH] <= 1                        ;
        imm_signex                   <= 0                        ;
        imm_byte                     <=(inst[1:0]==2'd1)? 4:1    ;
        bit_mode[`MQ_ARITH] <=(inst[1:0]==2'd0)?`BIT_MD_8 :
                                   (rex_w          )?`BIT_MD_64:
                                                     `BIT_MD_32;
        state                        <= S_MODRM_DEST_RM          ;
        substate_modrm_dest_rm       <= MODRM_DEST_RM_GRP_11     ;
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
        bit_mode[`MQ_ARITH] <=(~inst[0])?`BIT_MD_8:(rex_w)?`BIT_MD_64:`BIT_MD_32;
        efl_mode[`MQ_ARITH] <= 1;
        case (inst[5:3])
          3'b000 :begin opcode[`MQ_ARITH]<=(inst[2])?`MICRO_ADDI:`MICRO_ADD;name<="ADD";end
          3'b001 :begin opcode[`MQ_ARITH]<=(inst[2])?`MICRO_ADCI:`MICRO_ADC;name<="ADC";end
          3'b010 :begin opcode[`MQ_ARITH]<=(inst[2])?`MICRO_ANDI:`MICRO_AND;name<="AND";end
          3'b011 :begin opcode[`MQ_ARITH]<=(inst[2])?`MICRO_XORI:`MICRO_XOR;name<="XOR";end
          3'b100 :begin opcode[`MQ_ARITH]<=(inst[2])?`MICRO_ORI :`MICRO_OR ;name<="OR" ;end
          3'b101 :begin opcode[`MQ_ARITH]<=(inst[2])?`MICRO_SBBI:`MICRO_SBB;name<="SBB";end
          3'b110 :begin opcode[`MQ_ARITH]<=(inst[2])?`MICRO_SUBI:`MICRO_SUB;name<="SUB";end
          default:begin opcode[`MQ_ARITH]<=(inst[2])?`MICRO_CMPI:`MICRO_CMP;name<="CMP";end
        endcase
        if (inst[2]) begin
          reg_addr_d[`MQ_ARITH]<=`RAX_ADDR     ;
          reg_addr_s[`MQ_ARITH]<=`RAX_ADDR     ;
          imm_byte                      <=(inst[0])? 4:1;
          imm_to  [`MQ_ARITH]<= 1            ;
          imm_signex                    <= 1            ;
          state                         <= S_IMMEDIATE  ;
        end else begin
          opcode  [`MQ_LOAD ]<=(~inst[0])?`MICRO_LB:(rex_w)?`MICRO_LQ:`MICRO_LD;
          if (~inst[1]) begin
            opcode[`MQ_STORE]<=(~inst[0])?`MICRO_SB:(rex_w)?`MICRO_SQ:`MICRO_SD;
            state                     <= S_MODRM_DEST_RM;
          end else begin
            state                     <= S_MODRM_DEST_R ;
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
        reg_addr_d[`MQ_LOAD ]<=`REG_ADDR_W'({rex_b,inst[2:0]});
        reg_addr_s[`MQ_LOAD ]<=`RSP_ADDR                      ;
        opcode    [`MQ_ARITH]<=`MICRO_ADDI                    ;
        reg_addr_d[`MQ_ARITH]<=`RSP_ADDR                      ;
        reg_addr_s[`MQ_ARITH]<=`RSP_ADDR                      ;
        bit_mode  [`MQ_ARITH]<=`BIT_MD_64                   ;
        reg_addr_d[`MQ_STORE]<=`REG_ADDR_W'({rex_b,inst[2:0]});
        reg_addr_s[`MQ_STORE]<=`RSP_ADDR                      ;
        inst_valid                <= 1                             ;
        state                     <= S_OPCODE_1                    ;

        if (inst[3]) begin // Pop
          name <= "POP";
          opcode   [`MQ_LOAD ]<=`MICRO_LQ;
          immediate[`MQ_ARITH]<=`IMM_W'(signed'( 8));
        end else begin     // Push
          name <= "PUSH";
          immediate[`MQ_ARITH]<=`IMM_W'(signed'(-8));
          opcode   [`MQ_STORE]<=`MICRO_SQ           ;
        end
      end
      8'b011010?0: // Push imm8/16/32
      begin
        /***************************************
        * if (inst[1]) then imm8 else imm16/32.
        */
        // Use Stack Pointer in this instruction
        name <= "PUSH";
        opcode    [`MQ_RSRV1]<=`MICRO_MOVI         ;
        reg_addr_d[`MQ_RSRV1]<=`TMP_ADDR           ;
        opcode    [`MQ_RSRV2]<=`MICRO_ADDI         ;
        reg_addr_d[`MQ_RSRV2]<=`RSP_ADDR           ;
        reg_addr_s[`MQ_RSRV2]<=`RSP_ADDR           ;
        immediate [`MQ_RSRV2]<=`IMM_W'(signed'(-8));
        bit_mode  [`MQ_RSRV2]<=`BIT_MD_64        ;
        opcode    [`MQ_RSRV3]<=`MICRO_SB           ;
        reg_addr_d[`MQ_RSRV3]<=`TMP_ADDR           ;
        reg_addr_s[`MQ_RSRV3]<=`RSP_ADDR           ;
        imm_to    [`MQ_RSRV1]<= 1              ;
        imm_byte                  <=(inst[1])? 1:4;
        imm_signex                <= 1          ;
        state                     <= S_IMMEDIATE;
      end
      /*********************
      *     - Ret
      */
      8'hc2: // Ret imm16 (Near return)
      begin
        // Use Stack Pointer in this instruction
        name <= "RET";
        opcode    [`MQ_LOAD ] <=`MICRO_LQ          ;
        reg_addr_d[`MQ_LOAD ] <=`TMP_ADDR          ;
        reg_addr_s[`MQ_LOAD ] <=`RSP_ADDR          ;
        opcode    [`MQ_ARITH] <=`MICRO_ADDI        ;
        reg_addr_d[`MQ_ARITH] <=`RSP_ADDR          ;
        reg_addr_s[`MQ_ARITH] <=`RSP_ADDR          ;
        immediate [`MQ_ARITH] <=`IMM_W'(signed'(8));
        bit_mode  [`MQ_ARITH] <=`BIT_MD_64       ;
        opcode    [`MQ_RSRV1] <=`MICRO_JR          ;
        reg_addr_d[`MQ_RSRV1] <=`TMP_ADDR          ;
        opcode    [`MQ_RSRV2] <=`MICRO_ADDI        ;
        bit_mode  [`MQ_RSRV2] <=`BIT_MD_32       ;
        reg_addr_d[`MQ_RSRV2] <=`RSP_ADDR          ;
        reg_addr_s[`MQ_RSRV2] <=`RSP_ADDR          ;
        imm_to  [`MQ_RSRV2] <= 1             ;
        imm_byte                       <= 2             ;
        state                          <= S_IMMEDIATE   ;
      end
      8'hc3: // Ret (Near return)
      begin
        // Use Stack Pointer in this instruction
        name <= "RET";
        opcode    [`MQ_LOAD ] <=`MICRO_LQ          ;
        reg_addr_d[`MQ_LOAD ] <=`TMP_ADDR          ;
        reg_addr_s[`MQ_LOAD ] <=`RSP_ADDR          ;
        opcode    [`MQ_ARITH] <=`MICRO_ADDI        ;
        reg_addr_d[`MQ_ARITH] <=`RSP_ADDR          ;
        reg_addr_s[`MQ_ARITH] <=`RSP_ADDR          ;
        immediate [`MQ_ARITH] <=`IMM_W'(signed'(8));
        bit_mode  [`MQ_ARITH] <=`BIT_MD_64       ;
        opcode    [`MQ_RSRV1] <=`MICRO_JR          ;
        reg_addr_d[`MQ_RSRV1] <=`TMP_ADDR          ;
        inst_valid                 <= 1                 ;
        state                      <= S_OPCODE_1        ;
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
        opcode    [`MQ_RSRV1] <=`MICRO_MOVI               ;
        reg_addr_d[`MQ_RSRV1] <=`TMP_ADDR                 ;
        immediate [`MQ_RSRV1] <=`REG_W'(pc_of_this_inst)+5;
        opcode    [`MQ_RSRV2] <=`MICRO_ADDI               ;
        reg_addr_d[`MQ_RSRV2] <=`RSP_ADDR                 ;
        reg_addr_s[`MQ_RSRV2] <=`RSP_ADDR                 ;
        immediate [`MQ_RSRV2] <=`IMM_W'(signed'(-8))      ;
        bit_mode  [`MQ_RSRV2] <=`BIT_MD_64              ;
        opcode    [`MQ_RSRV3] <=`MICRO_SQ                 ;
        reg_addr_d[`MQ_RSRV3] <=`TMP_ADDR                 ;
        reg_addr_s[`MQ_RSRV3] <=`RSP_ADDR                 ;
        opcode    [`MQ_RSRV4] <=`MICRO_J                  ;
        disp_to [`MQ_RSRV4]   <= 1                        ;
        disp_byte                  <= 4                        ;
        rex                        <= rex                      ;
        state                      <= S_DISPLACEMENT           ;
      end
      /*********************
      *     - JMP
      */
      8'heb:
      begin
        name <= "JMP";
        opcode   [`MQ_RSRV1] <=`MICRO_J;
        disp_to[`MQ_RSRV1] <= 1;
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
        opcode  [`MQ_ARITH]<=`MICRO_MOV;
        bit_mode[`MQ_ARITH]<=(~inst[0])?`BIT_MD_8:(rex_w)?`BIT_MD_64:`BIT_MD_32;
        opcode  [`MQ_LOAD ]<=(~inst[0])?  `MICRO_LB:(rex_w)?   `MICRO_LQ:   `MICRO_LD;
        if (~inst[1]) begin
          opcode[`MQ_STORE]<=(~inst[0])?  `MICRO_SB:(rex_w)?   `MICRO_SQ:   `MICRO_SD;
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
        opcode  [`MQ_LOAD ]<=`MICRO_ADDI      ;// ADDI comes in pretending to be "Load".
        bit_mode[`MQ_LOAD ]<=`BIT_MD_32     ;
        opcode  [`MQ_ARITH]<=`MICRO_MOV       ;
        bit_mode[`MQ_ARITH]<=`BIT_MD_32     ;
        state                   <= S_MODRM_DEST_R  ;
        substate_modrm_dest_r   <= MODRM_DEST_R_LEA;
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
        opcode    [`MQ_ARITH] <=`MICRO_MOVI                    ;
        reg_addr_d[`MQ_ARITH] <=`REG_ADDR_W'({rex_b,inst[2:0]});
        imm_to  [`MQ_ARITH]   <= 1                             ;
        state                      <= S_IMMEDIATE                   ;
        if (inst[3]==0) begin
          bit_mode[`MQ_ARITH] <=`BIT_MD_8                    ;
          imm_byte                 <= 1                             ;
        end else begin
          bit_mode[`MQ_ARITH] <=rex_w?`BIT_MD_64:`BIT_MD_32;
          imm_byte                 <= 4                             ;
        end
      end
      /*********************
      *     - Jcc
      */
      8'h7?: // Jcc rel8
      begin
        name <= "JCC";
        case (inst[3:0])
          4'h0   :opcode[`MQ_RSRV1] <=`MICRO_JO ;
          4'h1   :opcode[`MQ_RSRV1] <=`MICRO_JNO;
          4'h2   :opcode[`MQ_RSRV1] <=`MICRO_JB ;
          4'h3   :opcode[`MQ_RSRV1] <=`MICRO_JAE;
          4'h4   :opcode[`MQ_RSRV1] <=`MICRO_JE ;
          4'h5   :opcode[`MQ_RSRV1] <=`MICRO_JNE;
          4'h6   :opcode[`MQ_RSRV1] <=`MICRO_JBE;
          4'h7   :opcode[`MQ_RSRV1] <=`MICRO_JA ;
          4'h8   :opcode[`MQ_RSRV1] <=`MICRO_JS ;
          4'h9   :opcode[`MQ_RSRV1] <=`MICRO_JNS;
          4'ha   :opcode[`MQ_RSRV1] <=`MICRO_JP ;
          4'hb   :opcode[`MQ_RSRV1] <=`MICRO_JNP;
          4'hc   :opcode[`MQ_RSRV1] <=`MICRO_JL ;
          4'hd   :opcode[`MQ_RSRV1] <=`MICRO_JGE;
          4'he   :opcode[`MQ_RSRV1] <=`MICRO_JLE;
          default:opcode[`MQ_RSRV1] <=`MICRO_JG ;
        endcase
        disp_to    [`MQ_RSRV1] <= 1;
        disp_byte                   <= 1;
        state                       <= S_DISPLACEMENT;
      end
      8'he3: // JCX rel8 (CX/ECX/RCX = 0)
      begin
        name <= "JCX";
        opcode   [`MQ_RSRV1] <=`MICRO_JCX;
        bit_mode [`MQ_RSRV1] <= rex_w ? `BIT_MD_64:`BIT_MD_32;
        disp_to  [`MQ_RSRV1] <= 1;
        disp_byte                 <= 1;
        disp_signex               <= 1;
        state                     <= S_DISPLACEMENT;
      end
      /******************************
      *     - Test : Logical Compare
      */
      8'b1000010?: // if (?=0) then TEST r/m8 r8 else TEST r/m16(32,64) r16(32,64)
      begin
        name <= "TEST";
        rex  <= rex   ;
        opcode  [`MQ_LOAD ]<=(~inst[0])?  `MICRO_LB:(rex_w)?   `MICRO_LQ:   `MICRO_LD;
        opcode  [`MQ_ARITH]<=(~inst[0])?`BIT_MD_8:(rex_w)?`BIT_MD_64:`BIT_MD_32;
        opcode  [`MQ_ARITH]<=`MICRO_TEST                                             ;
        efl_mode[`MQ_ARITH]<= 1;
        state                   <= S_MODRM_DEST_RM                                        ;
      end
      8'b1010100?: // if (?=0) then TEST AL,imm8 else TEST AX/EAX/RAX,imm16/32/32
      begin
        name <= "TEST";
        rex  <= rex   ;
        opcode  [`MQ_ARITH]<=`MICRO_TESTI                                            ;
        opcode  [`MQ_ARITH]<=(~inst[0])?`BIT_MD_8:(rex_w)?`BIT_MD_64:`BIT_MD_32;
        imm_byte                <=(~inst[0])? 1:4;
        imm_to  [`MQ_ARITH]<= 1             ;
        efl_mode[`MQ_ARITH]<= 1             ;
        state                   <= S_IMMEDIATE   ;
      end
      default:begin end
    endcase
  end

endmodule


`default_nettype wire
