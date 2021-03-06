`include "common_params.h"
`include "common_params_svfiles.h"

module fetch_phase_opcode_1 (
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

  integer i;

  always_comb begin
    // ELSEやDEFAULTを漏れなく書くのは怠すぎるので
    // 先頭にこれを書くことで妥協する
    rex    <= rex_as_src   ;
    valid  <=             0;
    
    // 本質はここから
    /****************************************
    * Default settings of micro instructions
    */
    name      <= "???";
    disp.size <= 0;
    disp.cnt  <= 0;
    disp.to   <= 0;
    imm.size  <= 0;
    imm.cnt   <= 0;
    imm.to    <= 0;
    state     <= make_state(OPCODE_1,DST_RM,GRP_0);
    for (i=0;i<`MQ_N;i=i+1) begin
      miinst[i] <= nop(pc);
    end

    // Priority Encoder
    // - So be careful when you rearrange the sentences.
    casez (inst)
      /**************************
      *       Prefixes
      */
      8'h4?:
      begin
        rex   <=inst[3:0];
        name  <="PREFIX";
      end// REX prefix
      8'h0f:
      begin
        state.obj <=OPCODE_2;
        name      <="PREFIX";
      end// Two-byte opcode escape
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
        for(i=0;i<`MQ_N;i=i+1) begin
          miinst[i].bmd <= bmd_det(inst[1:0]==2'd0, rex_w);
        end
        imm.to[`MQ_ARITH] <= 1;
        imm.size          <= imm_size_det(inst[1:0]==2'd0||inst[1:0]==2'd3,1);
        state             <= make_state(MODRM,DST_RM,GRP_1);
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
        for(i=0;i<`MQ_N;i=i+1) begin
          miinst[i].bmd <= bmd_det(inst[1:0]==2'd0, rex_w);
        end
        state <= make_state(MODRM,DST_RM,GRP_1A);
      end
      8'b1111011?:// Grp3
      begin
        // if (?=0) 8-bit else 16/32/64-bit mode.
        name                 <="PREFIX";
        miinst[`MQ_LOAD].bmd <= bmd_det(~inst[0],rex_w);
        state                <= make_state(MODRM,DST_RM,GRP_3);
      end
      8'hff:// Grp5, Call,Jmp,Push,etc...
      begin
        name                 <="PREFIX";
        miinst[`MQ_LOAD].bmd <= bmd_det(0,rex_w);
        state                <= make_state(MODRM,DST_RM,GRP_5);
      end
      8'b1100011?: // Grp11
      begin
        /****************************************************
        * if (inst[0]==0) then 8-bit else 16/32/64-bit mode.
        * The instructions in Grp11 don't need any Load-type
        * instruction.
        */
        name <= "Grp11";
        for(i=0;i<`MQ_N;i=i+1) begin
          miinst[i].bmd <= bmd_det(~inst[0], rex_w);
        end
        imm.to[`MQ_ARITH] <= 1                       ;
        imm.size          <= imm_size_det(~inst[0],1);
        state             <= make_state(MODRM,DST_RM,GRP_11);
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
        for(i=0;i<`MQ_N;i=i+1) begin
          miinst[i].bmd <= bmd_det(~inst[0], rex_w);
        end
        miinst[`MQ_ARITH].d <= RAX;
        miinst[`MQ_ARITH].s <= RAX;
        imm.size            <= imm_size_det(inst[2]&~inst[0],inst[2]);
        imm.to[`MQ_ARITH]   <= 1;
        case (inst[5:3])
          3'b000 :begin miinst[`MQ_ARITH].op<=(inst[2])? MIOP_ADDI:MIOP_ADD;name<="ADD";end
          3'b001 :begin miinst[`MQ_ARITH].op<=(inst[2])? MIOP_ADCI:MIOP_ADC;name<="ADC";end
          3'b010 :begin miinst[`MQ_ARITH].op<=(inst[2])? MIOP_ANDI:MIOP_AND;name<="AND";end
          3'b011 :begin miinst[`MQ_ARITH].op<=(inst[2])? MIOP_XORI:MIOP_XOR;name<="XOR";end
          3'b100 :begin miinst[`MQ_ARITH].op<=(inst[2])? MIOP_ORI :MIOP_OR ;name<="OR" ;end
          3'b101 :begin miinst[`MQ_ARITH].op<=(inst[2])? MIOP_SBBI:MIOP_SBB;name<="SBB";end
          3'b110 :begin miinst[`MQ_ARITH].op<=(inst[2])? MIOP_SUBI:MIOP_SUB;name<="SUB";end
          default:begin miinst[`MQ_ARITH].op<=(inst[2])? MIOP_CMPI:MIOP_CMP;name<="CMP";end
        endcase
        state <= make_state (
          inst[2] ? IMMEDIATE:MODRM,
          inst[1] ? DST_R    :DST_RM,
          GRP_0
        );
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
        
        valid     <= 1;
        state.obj <= OPCODE_1;
        if (inst[3]) begin
          name <= "POP";
          miinst[0] <=  load_on_pop(rega_t'({rex_b,inst[2:0]}),pc);
          miinst[1] <=  addi_on_pop(pc);
        end else begin
          name <= "PUSH";
          miinst[0] <=  addi_on_push(pc);
          miinst[1] <= store_on_push(rega_t'({rex_b,inst[2:0]}),pc);
        end
      end
      8'b011010?0: // Push imm8/16/32
      begin
        /***************************************
        * if (inst[1]) then imm8 else imm16/32.
        */
        // Use Stack Pointer in this instruction
        name <= "PUSH";
        miinst[0] <=   make_miinst(MIOP_MOVI,TMP,,,,inst[1]? BMD_08:BMD_32,pc);
        miinst[1] <=  addi_on_push(pc);
        miinst[2] <= store_on_push(TMP,pc);

        imm.to[0] <= 1;
        imm.size  <= imm_size_det(inst[1],1);
        state.obj <= IMMEDIATE;
      end
      /*********************
      *     - Ret
      */
      8'hc2: // Ret imm16 (Near return)
      begin
        // Use Stack Pointer in this instruction
        name <= "RET";
        miinst[0] <= load_on_pop(TMP,pc);
        miinst[1] <= addi_on_pop(pc);
        miinst[2] <= make_miinst(MIOP_JR  ,TMP,   ,,,BMD_32,pc);
        miinst[3] <= make_miinst(MIOP_ADDI,RSP,RSP,,,BMD_64,pc);
        imm.to[3] <= 1;
        imm.size  <= 2;
        state.obj <= IMMEDIATE;
      end
      8'hc3: // Ret (Near return)
      begin
        // Use Stack Pointer in this instruction
        name      <= "RET";
        miinst[0] <= load_on_pop(TMP,pc);
        miinst[1] <= addi_on_pop(pc);
        miinst[2] <= make_miinst(MIOP_JR,TMP,,,,BMD_32,pc);
        valid     <= 1;
        state.obj <= OPCODE_1;
      end
      8'hca:begin end // Ret imm16 (Far  return) 無視
      8'hcb:begin end // Ret       (Far  return) 無視
      /*********************
      *     - Leave: High Level Procedure Exit
      */
      8'hc9:// Set SP/ESP/RSP to BP/EBP/RBP, then pop BP/EBP/RBP.
      begin
        name      <= "LEAVE";
        miinst[0] <= make_miinst(MIOP_MOV,RSP,,RBP,,bmd_det(0,rex_w),pc);
        miinst[1] <= load_on_pop(RBP,pc);
        miinst[2] <= addi_on_pop(pc);
        valid     <= 1;
        state.obj <= OPCODE_1;
      end
      /********************************
      *     - In - Input from port
      */
      8'b1110010?: // In AL/AX/EAX,imm8
      begin
        name      <="IN";
      end
      8'b1110110?: // In AL/AX/EAX,DX
      begin
        name      <="IN";
      end
      /********************************
      *     - Out - Output to port
      */
      8'b1110011?: // Out imm8, AL/AX/EAX
      begin
        /**************************************
        * if (inst[0]==0) then AL else AX/EAX.
        */
        name      <= "OUT";
        imm.size  <=     1;
        imm.to[0] <=     1;
        miinst[0] <= make_miinst(MIOP_OUT,,,,,bmd_det(~inst[0],0),pc);
        state     <= make_state (IMMEDIATE,,);
      end
      /*********************
      *     - Call
      *       - Grp5あり
      */
      8'he8: // Call rel16(32)
      begin
        // Use Stack Pointer in this instruction
        name       <= "CALL";
        miinst [1] <=  addi_on_push(pc);
        miinst [2] <= store_on_push(RIP,pc);
        miinst [3] <=   make_miinst(MIOP_J,,,,,BMD_32,pc);
        disp.to[3] <= 1;
        disp.size  <= 4;
        state.obj  <= DISPLACEMENT;
      end
      /*********************
      *     - JMP
      */
      8'heb:
      begin
        name      <= "JMP";
        miinst [0]<= make_miinst(MIOP_J,,,,,BMD_32,pc);
        disp.to[0]<= 1;
        disp.size <= 1;
        state.obj <= DISPLACEMENT;
      end
      8'h9A:begin end // Call ptr16:16(32) 無視
      /*********************
      *     - Mov
      *     - Lea
      */
      8'b100010??:
      begin
        name <="MOV";
        miinst[`MQ_ARITH].op  <= MIOP_MOV;
        miinst[`MQ_LOAD ].bmd <= bmd_det(~inst[0],rex_w);
        miinst[`MQ_ARITH].bmd <= bmd_det(~inst[0],rex_w);
        miinst[`MQ_STORE].bmd <= bmd_det(~inst[0],rex_w);

        state <= make_state(MODRM,inst[1]? DST_R:DST_RM,GRP_0);
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
        name  <="LEA";
        state <= make_state(MODRM,DST_R,GRP_LEA);
        miinst[`MQ_LOAD ].bmd <= BMD_64;
        miinst[`MQ_ARITH].bmd <= BMD_64;
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
        name      <= "MOV";
        state     <= make_state(IMMEDIATE,,);
        imm.to[0] <= 1;
        imm.size  <= imm_size_det(~inst[3],1);
        miinst[0] <= make_miinst (MIOP_MOVI, rega_t'({rex_b,inst[2:0]}),,,,bmd_det(~inst[3],rex_w),pc);
      end
      /*********************
      *     - Jcc
      */
      8'h7?: // Jcc rel8
      begin
        name       <= "JCC";
        miinst [0] <= pre_jcc(inst[3:0],pc);
        disp.to[0] <= 1;
        disp.size  <= 1;
        state.obj  <= DISPLACEMENT;
      end
      8'he3: // JCX rel8 (CX/ECX/RCX = 0)
      begin
        name       <= "JCX";
        miinst [0] <= make_miinst(MIOP_JCX,,,,,bmd_det(0,rex_w),pc);
        disp.to[0] <= 1;
        disp.size  <= 1;
        state.obj  <= DISPLACEMENT;
      end
      /******************************
      *     - Test : Logical Compare
      */
      8'b1000010?: // if (?=0) then TEST r/m8 r8 else TEST r/m16(32,64) r16(32,64)
      begin
        name                  <= "TEST";
        miinst[`MQ_LOAD ].bmd <= bmd_det(~inst[0],rex_w);
        miinst[`MQ_ARITH].bmd <= bmd_det(~inst[0],rex_w);
        miinst[`MQ_ARITH].op  <= MIOP_TEST;
        state                 <= make_state(MODRM,DST_RM,GRP_0);
      end
      8'b1010100?: // if (?=0) then TEST AL,imm8 else TEST AX/EAX/RAX,imm16/32/32
      begin
        name      <= "TEST";
        miinst[0] <= make_miinst(MIOP_TESTI,RAX,RAX,,,bmd_det(~inst[0],rex_w),pc);
        imm.to[0] <= 1;
        imm.size  <= imm_size_det(~inst[0],1);
        state.obj <= IMMEDIATE;
      end
      default:begin end
    endcase
  end
endmodule
