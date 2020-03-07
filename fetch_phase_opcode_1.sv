`default_nettype none
`include "common_params.h"
`include "common_params_in_fetch_phase.h"

module fetch_phase_opcode_1 (
  input     inst_t   inst                    ,
  input     fstate   state_as_src            ,
  input   miinst_t   miinst_as_src[`MQ_N-1:0],
  input wire [3:0]   rex_as_src              ,
  output    fstate   state                   ,
  output  miinst_t   miinst       [`MQ_N-1:0],
  output reg [3:0]   rex                     //
);
  function fstate make_state(
    input fsust_obj  o,
    input fsubst_dst d,
    input fsubst_grp g,
    input name_t     n
  );
  begin
    make_state.n   <= n;
    make_state.obj <= o;
    make_state.dst <= d;
    make_state.grp <= g;
  end
  endfunction

  always_comb begin
    disp_byte   <= 0;
    disp_cnt    <= 0;
    imm_byte    <= 0;
    imm_cnt     <= 0;
    state       <= make_state(OPCODE_1,DST_RM,GRP_0,"???");
    for (i=0;i<`MQ_N;i=i+1) begin
      miinst [i]<= make_miinst(MIOP_NOP,0,0,0,0,BMD_32,pc);
      imm_to [i]<= 0;
      disp_to[i]<= 0;
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
        for(i=0;i<MQ_N;i=i+1) begin
          miinst[i].bmd <= bmd_det(inst[1:0]==2'd0, rex_w);
        end
        imm_to[`MQ_ARITH] <= 1;
        imm_signex        <= 1;
        imm_byte          <= imm_byte_det(inst[1:0]==2'd0||inst[1:0]==2'd3,1);
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
        for(i=0;i<MQ_N;i=i+1) begin
          miinst[i].bmd <= bmd_det(inst[1:0]==2'd0, rex_w);
        end
        state <= make_state(MODRM,DST_RM,GRP_1A);
      end
      8'b1111011?:// Grp3
      begin
        // if (?=0) 8-bit else 16/32/64-bit mode.

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
        for(i=0;i<MQ_N;i=i+1) begin
          miinst[i].bmd <= bmd_det(~inst[0], rex_w);
        end
        imm_to[`MQ_ARITH] <= 1                       ;
        imm_signex        <= 0                       ;
        imm_byte          <= imm_byte_det(~inst[0],1);
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
        for(i=0;i<MQ_N;i=i+1) begin
          miinst[i].bmd <= bmd_det(~inst[0], rex_w);
        end
        miinst[`MQ_ARITH].d <= `RAX_ADDR;
        miinst[`MQ_ARITH].s <= `RAX_ADDR;
        imm_byte            <= imm_byte_det(inst[2]&~inst[0],inst[2]);
        imm_to[`MQ_ARITH]   <= 1;
        imm_signex          <= 1;
        case (inst[5:3])
          3'b000 :begin miinst[`MQ_ARITH].opcode<=(inst[2])? MIOP_ADDI:MIOP_ADD;miinst[`MQ_ARITH].name<="ADD";end
          3'b001 :begin miinst[`MQ_ARITH].opcode<=(inst[2])? MIOP_ADCI:MIOP_ADC;miinst[`MQ_ARITH].name<="ADC";end
          3'b010 :begin miinst[`MQ_ARITH].opcode<=(inst[2])? MIOP_ANDI:MIOP_AND;miinst[`MQ_ARITH].name<="AND";end
          3'b011 :begin miinst[`MQ_ARITH].opcode<=(inst[2])? MIOP_XORI:MIOP_XOR;miinst[`MQ_ARITH].name<="XOR";end
          3'b100 :begin miinst[`MQ_ARITH].opcode<=(inst[2])? MIOP_ORI :MIOP_OR ;miinst[`MQ_ARITH].name<="OR" ;end
          3'b101 :begin miinst[`MQ_ARITH].opcode<=(inst[2])? MIOP_SBBI:MIOP_SBB;miinst[`MQ_ARITH].name<="SBB";end
          3'b110 :begin miinst[`MQ_ARITH].opcode<=(inst[2])? MIOP_SUBI:MIOP_SUB;miinst[`MQ_ARITH].name<="SUB";end
          default:begin miinst[`MQ_ARITH].opcode<=(inst[2])? MIOP_CMPI:MIOP_CMP;miinst[`MQ_ARITH].name<="CMP";end
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
          miinst[0] <=  load_on_pop(`REG_ADDR_W'({rex_b,inst[2:0]},pc);
          miinst[1] <=  addi_on_pop(pc);
        end else begin
          name <= "PUSH";
          miinst[0] <=  addi_on_push(pc);
          miinst[1] <= store_on_push(`REG_ADDR_W'({rex_b,inst[2:0]},pc);
        end
      end
      8'b011010?0: // Push imm8/16/32
      begin
        /***************************************
        * if (inst[1]) then imm8 else imm16/32.
        */
        // Use Stack Pointer in this instruction
        name <= "PUSH";
        miinst[0] <=   make_miinst(MIOP_MOVI,`TMP_ADDR,0,0,0,inst[1]? BMD_08:BMD_32,pc);
        miinst[1] <=  addi_on_push(pc);
        miinst[2] <= store_on_push(`TMP_ADDR,pc);

        imm_to[0] <= 1;
        imm_byte  <= imm_byte_det(inst[1],1);
        imm_signex<= 1;
        state.obj <= IMMEDIATE;
      end
      /*********************
      *     - Ret
      */
      8'hc2: // Ret imm16 (Near return)
      begin
        // Use Stack Pointer in this instruction
        name <= "RET";
        miinst[0] <= load_on_pop(`TMP_ADDR,pc);
        miinst[1] <= addi_on_pop(pc);
        miinst[2] <= make_miinst(MIOP_JR  ,`TMP_ADDR,        0,0,0,BMD_32,pc);
        miinst[3] <= make_miinst(MIOP_ADDI,`RSP_ADDR,`RSP_ADDR,0,0,BMD_64,pc);
        imm_to[3] <= 1;
        imm_byte  <= 2;
        state.obj <= IMMEDIATE;
      end
      8'hc3: // Ret (Near return)
      begin
        // Use Stack Pointer in this instruction
        name      <= "RET";
        miinst[0] <= load_on_pop(`TMP_ADDR,pc);
        miinst[1] <= addi_on_pop(pc);
        miinst[2] <= make_miinst(MIOP_JR  ,`TMP_ADDR,0,0,0,BMD_32,pc);
        valid     <= 1;
        state.obj <= OPCODE_1;
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
        name       <= "CALL";
        miinst [1] <=  addi_on_push(pc);
        miinst [2] <= store_on_push(`RIP_ADDR);
        miinst [3] <=   make_miinst(MIOP_J,0,0,0,0,BMD_32,pc);
        disp_to[3] <= 1;
        disp_byte  <= 4;
        state.obj  <= DISPLACEMENT;
      end
      /*********************
      *     - JMP
      */
      8'heb:
      begin
        name      <= "JMP";
        miinst [0]<= make_miinst(MIOP_J,0,0,0,0,BMD_32,pc);
        disp_to[0]<= 1;
        disp_byte <= 1;
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
        miinst[`MQ_ARITH].opcode <= MIOP_MOV;
        miinst[`MQ_LOAD ].bmd    <= bmd_det(~inst[0],rex_w);
        miinst[`MQ_ARITH].bmd    <= bmd_det(~inst[0],rex_w);
        miinst[`MQ_STORE].bmd    <= bmd_det(~inst[0],rex_w);

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
        imm_to[0] <= 1;
        imm_byte  <= imm_byte_det(~inst[3],1);
        miinst[0] <= make_miinst (
          MIOP_MOVI,
          rega_t'({rex_b,inst[2:0]}),
          0,0,0,
          bmd_det(~inst[3],rex_w),
          pc
        );
      end
      /*********************
      *     - Jcc
      */
      8'h7?: // Jcc rel8
      begin
        name       <= "JCC";
        miinst [0] <= pre_jcc(inst[3:0],pc);
        disp_to[0] <= 1;
        disp_byte  <= 1;
        disp_signex<= 1;
        state.obj  <= DISPLACEMENT;
      end
      8'he3: // JCX rel8 (CX/ECX/RCX = 0)
      begin
        name       <= "JCX";
        miinst [0] <= make_miinst(MIOP_JCX,0,0,0,0,bmd_det(0,rex_w),pc);
        disp_to[0] <= 1;
        disp_byte  <= 1;
        state.obj  <= DISPLACEMENT;
      end
      /******************************
      *     - Test : Logical Compare
      */
      8'b1000010?: // if (?=0) then TEST r/m8 r8 else TEST r/m16(32,64) r16(32,64)
      begin
        name                    <= "TEST";
        miinst[`MQ_LOAD ].bmd   <= bmd_det(~inst[0],rex_w);
        miinst[`MQ_ARITH].bmd   <= bmd_det(~inst[0],rex_w);
        miinst[`MQ_ARITH].opcode<= MIOP_TEST;
        state                   <= make_state(MODRM,DST_RM,GRP_0);
      end
      8'b1010100?: // if (?=0) then TEST AL,imm8 else TEST AX/EAX/RAX,imm16/32/32
      begin
        name      <= "TEST";
        miinst[0] <= make_miinst(
          MIOP_TESTI,
          `RAX_ADDR,
          `RAX_ADDR,
          0,0,
          bmd_det(~inst[0],rex_w),
          pc
        );
        imm_to[0] <= 1;
        imm_byte  <= imm_byte_det(~inst[0],1);
        state.obj <= IMMEDIATE;
      end
      default:begin end
    endcase
  end

endmodule

`default_nettype wire
