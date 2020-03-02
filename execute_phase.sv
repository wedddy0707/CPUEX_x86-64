`default_nettype none
`include "common_params.h"

module execute_phase (
  input wire [`OPCODE_W  -1:0] de_opcode        ,
  input wire [`REG_ADDR_W-1:0] de_reg_addr_d    ,
  input wire [`REG_W     -1:0] de_d             ,
  input wire [`REG_W     -1:0] de_s             ,
  input wire [`REG_W     -1:0] de_t             ,
  input wire [`IMM_W     -1:0] de_immediate     ,
  input wire [`DISP_W    -1:0] de_displacement  ,
  input wire [`BIT_MODE_W-1:0] de_bit_mode      ,
  input wire [`ADDR_W    -1:0] de_pc            ,
  input wire [`REG_W     -1:0] gpr  [`REG_N-1:0],
  output reg [`REG_W     -1:0] exe_d            ,
  output reg [`ADDR_W    -1:0] exe_bd           ,
  output reg                   exe_be           ,
  output reg                   exe_eflags_update,
  output reg [`REG_W     -1:0] exe_eflags       ,
  output reg [`OPCODE_W  -1:0] ew_opcode        ,
  output reg [`REG_ADDR_W-1:0] ew_reg_addr_d    ,
  output reg [`REG_W     -1:0] ew_d             ,
  output reg [            2:0] ew_ld_offset     ,
  output reg [`ADDR_W    -1:0] mem_addr         ,
  output reg [`REG_W     -1:0] st_data          ,
  output reg [`DATA_W/8  -1:0] we               ,
  input wire                   clk              ,
  input wire                   rstn
);
  wire [`REG_W-1:0] exe_d;
  wire [`REG_W-1:0] cmp_d;

  assign exe_eflags_update =
    (de_opcode==`MICRO_CMP ) |
    (de_opcode==`MICRO_CMPI) ;

  assign exe_eflags =
    (de_opcode==`MICRO_CMP ) ? cmp_d :
    (de_opcode==`MICRO_CMPI) ? cmp_d : 0;

  always @(posedge clk) begin
    ew_d          <= ~rstn ? 0 : exe_d;
    ew_opcode     <= ~rstn ? 0 : de_opcode;
    ew_reg_addr_d <= ~rstn ? 0 : de_reg_addr_d;
  end

  alu alu_1 (
    .d       (exe_d           ),
    .opcode  (de_opcode       ),
    .s       (de_s            ),
    .t       (de_t            ),
    .imm     (de_immediate    ),
    .bit_mode(de_bit_mode     )
  );

  execute_memory_access mem_1 (
    .opcode   (de_opcode   ),
    .d        (de_d        ),
    .s        (de_s        ),
    .t        (de_t        ),
    .imm      (de_immediate),
    .mem_addr (mem_addr    ),
    .ld_offset(ew_ld_offset),
    .st_data  (st_data     ),
    .we       (we          )
  );
  execute_branch br_1 (
    .opcode           (de_opcode     ),
    .d                (de_d          ),
    .imm              (de_immediate  ),
    .pc               (de_pc         ),
    .eflags           (gpr[`EFL_ADDR]),
    .rcx              (gpr[`RCX_ADDR]),
    .bit_mode         (de_bit_mode   ),
    .branch_direction (exe_bd        ),
    .branch_enable    (exe_be        )
  );
endmodule

module execute_memory_access (
  input wire [`OPCODE_W-1:0] opcode   ,
  input wire [`REG_W   -1:0] d        ,
  input wire [`REG_W   -1:0] s        ,
  input wire [`REG_W   -1:0] t        ,
  input wire [`IMM_W   -1:0] imm      ,
  output reg [`ADDR_W  -1:0] mem_addr ,
  output reg [          2:0] ld_offset,
  output reg [`REG_W   -1:0] st_data  ,
  output reg [`DATA_W/8-1:0] we       ,
  input wire                 clk      ,
  input wire                 rstn
);
  wire [`ADDR_W:0] a = signed'({1'b0,s})+(`ADDR_W+1)'(signed'(imm));

  always @(posedge clk) begin
    st_data   <= ~rstn ? 0 : d;
    mem_addr  <= ~rstn ? 0 : {3'b0,a[`ADDR_W-1:3]};
    ld_offset <= ~rstn ? 0 : a[2:0];
    we        <= ~rstn ? 0 :
      (opcode==`MICRO_SB) ? 8'h1  << a[2:0] :
      (opcode==`MICRO_SD) ? 8'h0f << a[2:0] :
      (opcode==`MICRO_SQ) ? 8'hff           : 8'd0;
  end
endmodule

module execute_branch (
  input wire [`OPCODE_W  -1:0] opcode          ,
  input wire [`REG_W     -1:0] d               ,
  input wire [`IMM_W     -1:0] imm             ,
  input wire [`ADDR_W    -1:0] pc              ,
  input wire [`REG_W     -1:0] eflags          ,
  input wire [`REG_W     -1:0] rcx             ,
  input wire [`BIT_MODE_W-1:0] bit_mode        ,
  output reg [`ADDR_W    -1:0] branch_direction,
  output reg                   branch_enable
);
  assign branch_enable =
    // 無条件分岐
    (opcode==`MICRO_J  ) ?  1              :
    (opcode==`MICRO_JR ) ?  1              :
    // 条件分岐 Jcc
    (opcode==`MICRO_JA ) ?  above          :
    (opcode==`MICRO_JAE) ?  above   | equal:
    (opcode==`MICRO_JB ) ?  below          :
    (opcode==`MICRO_JBE) ?  below   | equal:
    (opcode==`MICRO_JC ) ?  carry          :
    (opcode==`MICRO_JE ) ?  equal          :
    (opcode==`MICRO_JG ) ?  greater        :
    (opcode==`MICRO_JG ) ?  greater | equal:
    (opcode==`MICRO_JL ) ?  less           :
    (opcode==`MICRO_JLE) ?  less    | equal:
    (opcode==`MICRO_JO ) ?  overflow       :
    (opcode==`MICRO_JP ) ?  parity         :
    (opcode==`MICRO_JS ) ?  sign           :
    (opcode==`MICRO_JNE) ? ~equal          :
    (opcode==`MICRO_JNP) ? ~parity         :
    (opcode==`MICRO_JNS) ? ~sign           :
    (opcode==`MICRO_JNO) ? ~overflow       :
    // 条件分岐 JCX
    (opcode==`MICRO_JCX) ?  (
    (bit_mode==`BIT_MODE_32) ? ~|rcx[31:0] :
    /*       ==`BIT_MODE_64 */ ~|rcx[63:0]
    )                                      : 0;

  assign branch_direction =
    // 無条件分岐
    (opcode==`MICRO_J  ) ? type_rel :
    (opcode==`MICRO_JR ) ? type_reg :
    // 条件分岐 Jcc
    (opcode==`MICRO_JA ) ? type_rel :
    (opcode==`MICRO_JAE) ? type_rel :
    (opcode==`MICRO_JB ) ? type_rel :
    (opcode==`MICRO_JBE) ? type_rel :
    (opcode==`MICRO_JC ) ? type_rel :
    (opcode==`MICRO_JE ) ? type_rel :
    (opcode==`MICRO_JG ) ? type_rel :
    (opcode==`MICRO_JG ) ? type_rel :
    (opcode==`MICRO_JL ) ? type_rel :
    (opcode==`MICRO_JLE) ? type_rel :
    (opcode==`MICRO_JO ) ? type_rel :
    (opcode==`MICRO_JP ) ? type_rel :
    (opcode==`MICRO_JS ) ? type_rel :
    (opcode==`MICRO_JNE) ? type_rel :
    (opcode==`MICRO_JNP) ? type_rel :
    (opcode==`MICRO_JNS) ? type_rel :
    (opcode==`MICRO_JNO) ? type_rel :
    // 条件分岐 JCX
    (opcode==`MICRO_JCX) ? type_rel : 0;

  wire above   ,
       below   ,
       carry   ,
       equal   ,
       greater ,
       less    ,
       overflow,
       parity  ,
       sign    ;
  
  wire [`ADDR_W-1:0] type_reg =`ADDR_W'(d)               ;
  wire [`ADDR_W-1:0] type_rel = pc+`ADDR_W'(signed'(imm));

  condition_clarifier condition_clarifier_1 (
    .eflags  (eflags  ),
    .above   (above   ),
    .below   (below   ),
    .carry   (carry   ),
    .equal   (equal   ),
    .greater (greater ),
    .less    (less    ),
    .overflow(overflow),
    .parity  (parity  ),
    .sign    (sign    )
  );
endmodule

`default_nettype wire
