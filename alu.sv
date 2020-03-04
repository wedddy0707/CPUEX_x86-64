`default_nettype none
`include "common_params.h"

module alu (
  output reg [`REG_W     -1:0] d            ,
  input wire [`OPCODE_W  -1:0] opcode       ,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`IMM_W     -1:0] imm          ,
  input wire [`BIT_MODE_W-1:0] bit_mode     ,
  output reg [`REG_W     -1:0] eflags       ,
  output reg                   eflags_update,
  input wire [`REG_W     -1:0] eflags_as_src
);
  wire [`REG_W-1:0] add_d      ;
  wire [`REG_W-1:0] sub_d      ;
  wire [`REG_W-1:0] sll_d      ;
  wire [`REG_W-1:0] and_d      ;
  wire [`REG_W-1:0]  or_d      ;
  wire [`REG_W-1:0] xor_d      ;
  wire [`REG_W-1:0] mov_d      ;
  wire [`REG_W-1:0] cmp_d      ;
  wire [`REG_W-1:0] test_d     ;
  wire [`REG_W-1:0] adc_d      ;
  wire [`REG_W-1:0] sbb_d      ;
  wire [`REG_W-1:0] add_eflags ;
  wire [`REG_W-1:0] sub_eflags ;
  wire [`REG_W-1:0] sll_eflags ;
  wire [`REG_W-1:0] and_eflags ;
  wire [`REG_W-1:0]  or_eflags ;
  wire [`REG_W-1:0] xor_eflags ;
  wire [`REG_W-1:0] mov_eflags ;
  wire [`REG_W-1:0] cmp_eflags ;
  wire [`REG_W-1:0] test_eflags;
  wire [`REG_W-1:0] adc_eflags ;
  wire [`REG_W-1:0] sbb_eflags ;

  wire [`MICRO_W-1:0] opcode_reformed;
  wire [`REG_W  -1:0]      s_reformed;
  wire [`REG_W  -1:0]      t_reformed;
  
  assign {d,eflags} =
    (opcode_reformed==`MICRO_ADD ) ? {add_d,add_eflags}:
    (opcode_reformed==`MICRO_AND ) ? {and_d,and_eflags}:
    (opcode_reformed==`MICRO_OR  ) ? { or_d, or_eflags}:
    (opcode_reformed==`MICRO_XOR ) ? {xor_d,xor_eflags}: 0;

  assign eflags_update =
    (opcode_reformed==`MICRO_ADD) ? 1:
    (opcode_reformed==`MICRO_AND) ? 1: 0;

  reform_src_in_alu reform_src_in_alu_1 (
    .opcode         (opcode                   ),
    .s              (s                        ),
    .t              (t                        ),
    .imm            (imm                      ),
    .cf             (eflags_as_src[`EFLAGS_CF]),
    .opcode_reformed(opcode_reformed          ),
    .s_reformed     (s_reformed               ),
    .t_reformed     (t_reformed               )
  );
  execute_add add_1 (
    .d            (add_d        ),
    .s            (s_reformed   ),
    .t            (t_reformed   ),
    .bit_mode     (bit_mode     ),
    .eflags       (add_eflags   ),
    .eflags_as_src(eflags_as_src)
  );
  execute_sll sll_1 (
    .d            (sll_d        ),
    .s            (s_reformed   ),
    .t            (t_reformed   ),
    .bit_mode     (bit_mode     ),
    .eflags       (sll_eflags   ),
    .eflags_as_src(eflags_as_src)
  );
  execute_and and_1 (
    .d            (and_d        ),
    .s            (s_reformed   ),
    .t            (t_reformed   ),
    .bit_mode     (bit_mode     ),
    .eflags       (and_eflags   ),
    .eflags_as_src(eflags_as_src)
  );
  execute_or or_1 (
    .d            (or_d         ),
    .s            (s_reformed   ),
    .t            (t_reformed   ),
    .bit_mode     (bit_mode     ),
    .eflags       (or_eflags    ),
    .eflags_as_src(eflags_as_src)
  );
  execute_xor xor_1 (
    .d            (xor_d        ),
    .s            (s_reformed   ),
    .t            (t_reformed   ),
    .bit_mode     (bit_mode     ),
    .eflags       (xor_eflags   ),
    .eflags_as_src(eflags_as_src)
  );
endmodule

module reform_src_in_alu (
  input wire [`MICRO_W-1:0] opcode         ,
  input wire [`REG_W  -1:0] s              ,
  input wire [`REG_W  -1:0] t              ,
  input wire [`IMM_W  -1:0] imm            ,
  input wire                cf             ,
  output reg [`MICRO_W-1:0] opcode_reformed,
  output reg [`REG_W  -1:0] s_reformed     ,
  output reg [`REG_W  -1:0] t_reformed     //
);
  function [`REG_W-1:0] neg (input [`REG_W-1:0] x);
  begin
    neg = (~x)+`REG_W'd1;
  end
  endfunction

  wire [`REG_W-1:0]      z = `REG_W'd0;
  wire [`REG_W-1:0] imm_sx = {{(`REG_W-`IMM_W){imm[`IMM_W-1]}},imm};
  wire [`REG_W-1:0] imm_zx = {{(`REG_W-`IMM_W){         1'b0}},imm};

  assign {opcode_reformed,s_reformed,t_reformed} =
    (opcode==`MICRO_ADDI ) ? {`MICRO_ADD,s,imm_sx                 }:
    (opcode==`MICRO_ADCI ) ? {`MICRO_ADD,s,imm_sx    +`REG_W'(cf) }:
    (opcode==`MICRO_SUBI ) ? {`MICRO_ADD,s,neg(imm_sx)            }:
    (opcode==`MICRO_SBBI ) ? {`MICRO_ADD,s,neg(imm_sx+`REG_W'(cf))}:
    (opcode==`MICRO_MULI ) ? {`MICRO_MUL,s,    imm_sx             }:
    (opcode==`MICRO_DIVI ) ? {`MICRO_DIV,s,    imm_sx             }:
    (opcode==`MICRO_ANDI ) ? {`MICRO_AND,s,    imm_zx             }:
    (opcode==`MICRO_ORI  ) ? {`MICRO_OR ,s,    imm_zx             }:
    (opcode==`MICRO_XORI ) ? {`MICRO_XOR,s,    imm_zx             }:
    (opcode==`MICRO_SLLI ) ? {`MICRO_SLL,s,    imm_zx             }:
    (opcode==`MICRO_SRLI ) ? {`MICRO_SRL,s,    imm_zx             }:
    (opcode==`MICRO_SRAI ) ? {`MICRO_SRA,s,    imm_zx             }:
    (opcode==`MICRO_MOVI ) ? {`MICRO_OR ,z,    imm_zx             }:
    (opcode==`MICRO_CMPI ) ? {`MICRO_ADD,s,neg(imm_sx)            }:
    (opcode==`MICRO_TESTI) ? {`MICRO_AND,s,    imm_zx             }:
    (opcode==`MICRO_ADD  ) ? {`MICRO_ADD,s,    t                  }:
    (opcode==`MICRO_SUB  ) ? {`MICRO_ADD,s,neg(t)                 }:
    (opcode==`MICRO_MUL  ) ? {`MICRO_MUL,s,    t                  }:
    (opcode==`MICRO_DIV  ) ? {`MICRO_DIV,s,    t                  }:
    (opcode==`MICRO_AND  ) ? {`MICRO_AND,s,    t                  }:
    (opcode==`MICRO_OR   ) ? {`MICRO_OR ,s,    t                  }:
    (opcode==`MICRO_XOR  ) ? {`MICRO_XOR,s,    t                  }:
    (opcode==`MICRO_SLL  ) ? {`MICRO_SLL,s,    t                  }:
    (opcode==`MICRO_SRL  ) ? {`MICRO_SRL,s,    t                  }:
    (opcode==`MICRO_SRA  ) ? {`MICRO_SRA,s,    t                  }:
    (opcode==`MICRO_MOV  ) ? {`MICRO_OR ,z,    t                  }:
    (opcode==`MICRO_CMP  ) ? {`MICRO_ADD,s,neg(t)                 }:
    (opcode==`MICRO_TEST ) ? {`MICRO_AND,s,    t                  }:
    (opcode==`MICRO_ADC  ) ? {`MICRO_ADD,s,    t+`REG_W'(cf)      }:
    (opcode==`MICRO_SBB  ) ? {`MICRO_ADD,s,neg(t+`REG_W'(cf))     }:
                            {opcode    ,s,    t                  };
endmodule

module primitive_add #(
  parameter BW = 32
) (
  input wire [BW-1:0] s , // SRC1
  input wire [BW-1:0] t , // SRC2
  output reg [BW-1:0] d , // DEST
  output reg          of, // Overflow
  output reg          sf, // Sign
  output reg          cf, // Carry
  output reg          af, // Adjust
  output reg          zf, // Zero
  output reg          pf  // Parity
);
  assign {cf,d}=$signed({s[BW-1],s})+$signed({t[BW-1],t});

  assign of = ((d[BW-1])&(~s[BW-1])&(~t[BW-1]))|((~d[BW-1])&(s[BW-1])&(t[BW-1]));
  assign sf =   d[BW-1];
  assign af =     0;
  assign zf = ~(|d);
  assign pf = ~(^d);
endmodule

module execute_add (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);

  wire [ 7:0] d08;
  wire [15:0] d16;
  wire [31:0] d32;
  wire [63:0] d64;

  wire of08,sf08,cf08,af08,zf08,pf08;
  wire of16,sf16,cf16,af16,zf16,pf16;
  wire of32,sf32,cf32,af32,zf32,pf32;
  wire of64,sf64,cf64,af64,zf64,pf64;
  wire of  ,sf  ,cf  ,af  ,zf  ,pf  ;

  primitive_add #( 8)add_08(.s(s[ 7:0]),.t(t[ 7:0]),.d(d08),.of(of08),.sf(sf08),.cf(cf08),.af(af08),.zf(zf08),.pf(pf08));
  primitive_add #(16)add_16(.s(s[15:0]),.t(t[15:0]),.d(d16),.of(of16),.sf(sf16),.cf(cf16),.af(af16),.zf(zf16),.pf(pf16));
  primitive_add #(32)add_32(.s(s[31:0]),.t(t[31:0]),.d(d32),.of(of32),.sf(sf32),.cf(cf32),.af(af32),.zf(zf32),.pf(pf32));
  primitive_add #(64)add_64(.s(s[63:0]),.t(t[63:0]),.d(d64),.of(of64),.sf(sf64),.cf(cf64),.af(af64),.zf(zf64),.pf(pf64));

  assign {d,of,sf,cf,af,zf,pf} =
    (bit_mode==`BIT_MODE_8 ) ? {`REG_W'(signed'(d08)),of08,sf08,cf08,af08,zf08,pf08}:
    (bit_mode==`BIT_MODE_16) ? {`REG_W'(signed'(d16)),of16,sf16,cf16,af16,zf16,pf16}:
    (bit_mode==`BIT_MODE_32) ? {`REG_W'(signed'(d32)),of32,sf32,cf32,af32,zf32,pf32}:
                               {`REG_W'(signed'(d64)),of64,sf64,cf64,af64,zf64,pf64};
  genvar i;
  generate
  begin
    for (i=0;i<`REG_W;i=i+1) begin: set_eflags
      assign eflags[i] =
        (i==`EFLAGS_OF) ? of:
        (i==`EFLAGS_SF) ? sf:
        (i==`EFLAGS_ZF) ? zf:
        (i==`EFLAGS_AF) ? af:
        (i==`EFLAGS_CF) ? cf:
        (i==`EFLAGS_PF) ? pf: eflags_as_src[i];
    end
  end
  endgenerate
endmodule

module execute_adc (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [`REG_W-1:0] t_with_carry = t+`REG_W'(eflags_as_src[`EFLAGS_CF]);
  
  execute_add add_1 (
    .d            (d            ),
    .eflags       (eflags       ),
    .eflags_as_src(eflags_as_src),
    .s            (s            ),
    .t            (t_with_carry ),
    .bit_mode     (bit_mode     )
  );
endmodule

module execute_sub (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [`REG_W-1:0] neg_t = (~t)+1;

  execute_add add_1 (
    .d            (d            ),
    .eflags       (eflags       ),
    .eflags_as_src(eflags_as_src),
    .s            (s            ),
    .t            (neg_t        ),
    .bit_mode     (bit_mode     )
  );
endmodule

module execute_sbb (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [`REG_W-1:0] t_with_borrow = t+`REG_W'(eflags_as_src[`EFLAGS_CF]);
  
  execute_sub sub_1 (
    .d            (d            ),
    .eflags       (eflags       ),
    .eflags_as_src(eflags_as_src),
    .s            (s            ),
    .t            (t_with_borrow),
    .bit_mode     (bit_mode     )
  );
endmodule

module execute_and (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [`REG_W:0] d_with_bits_maximum =
    (`REG_W+1)'(s)&(`REG_W+1)'(t);

  assign d =
    (bit_mode==`BIT_MODE_8 ) ? `REG_W'(d_with_bits_maximum[ 7:0]):
    (bit_mode==`BIT_MODE_16) ? `REG_W'(d_with_bits_maximum[15:0]):
    (bit_mode==`BIT_MODE_32) ? `REG_W'(d_with_bits_maximum[31:0]):
                               `REG_W'(d_with_bits_maximum[63:0]);
  wire msb =
    (bit_mode==`BIT_MODE_8 ) ? d_with_bits_maximum[ 7]:
    (bit_mode==`BIT_MODE_16) ? d_with_bits_maximum[15]:
    (bit_mode==`BIT_MODE_32) ? d_with_bits_maximum[31]:
                               d_with_bits_maximum[63];
  wire zero =
    (bit_mode==`BIT_MODE_8 ) ? d_with_bits_maximum[ 7:0]== 8'd0:
    (bit_mode==`BIT_MODE_16) ? d_with_bits_maximum[15:0]==16'd0:
    (bit_mode==`BIT_MODE_32) ? d_with_bits_maximum[31:0]==32'd0:
                               d_with_bits_maximum[63:0]==64'd0;
  wire parity =
    (bit_mode==`BIT_MODE_8 ) ? ~(^d_with_bits_maximum[ 7:0]):
    (bit_mode==`BIT_MODE_16) ? ~(^d_with_bits_maximum[15:0]):
    (bit_mode==`BIT_MODE_32) ? ~(^d_with_bits_maximum[31:0]):
                               ~(^d_with_bits_maximum[63:0]);
  genvar i;
  generate
  begin
    for (i=0;i<`REG_W;i=i+1) begin: set_eflags
      assign eflags[i] =
        (i==`EFLAGS_OF) ? 0     :
        (i==`EFLAGS_SF) ? msb   :
        (i==`EFLAGS_ZF) ? zero  :
        (i==`EFLAGS_AF) ? 0     :
        (i==`EFLAGS_CF) ? 0     :
        (i==`EFLAGS_PF) ? parity: eflags_as_src[i];
    end
  end
  endgenerate
endmodule

module execute_or (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [`REG_W:0] d_with_bits_maximum =
    (`REG_W+1)'(s)|(`REG_W+1)'(t);

  assign d =
    (bit_mode==`BIT_MODE_8 ) ? `REG_W'(d_with_bits_maximum[ 7:0]):
    (bit_mode==`BIT_MODE_16) ? `REG_W'(d_with_bits_maximum[15:0]):
    (bit_mode==`BIT_MODE_32) ? `REG_W'(d_with_bits_maximum[31:0]):
                               `REG_W'(d_with_bits_maximum[63:0]);
  wire msb =
    (bit_mode==`BIT_MODE_8 ) ? d_with_bits_maximum[ 7]:
    (bit_mode==`BIT_MODE_16) ? d_with_bits_maximum[15]:
    (bit_mode==`BIT_MODE_32) ? d_with_bits_maximum[31]:
                               d_with_bits_maximum[63];
  wire zero =
    (bit_mode==`BIT_MODE_8 ) ? d_with_bits_maximum[ 7:0]== 8'd0:
    (bit_mode==`BIT_MODE_16) ? d_with_bits_maximum[15:0]==16'd0:
    (bit_mode==`BIT_MODE_32) ? d_with_bits_maximum[31:0]==32'd0:
                               d_with_bits_maximum[63:0]==64'd0;
  wire parity =
    (bit_mode==`BIT_MODE_8 ) ? ~(^d_with_bits_maximum[ 7:0]):
    (bit_mode==`BIT_MODE_16) ? ~(^d_with_bits_maximum[15:0]):
    (bit_mode==`BIT_MODE_32) ? ~(^d_with_bits_maximum[31:0]):
                               ~(^d_with_bits_maximum[63:0]);
  genvar i;
  generate
  begin
    for (i=0;i<`REG_W;i=i+1) begin: set_eflags
      assign eflags[i] =
        (i==`EFLAGS_OF) ? 0     :
        (i==`EFLAGS_SF) ? msb   :
        (i==`EFLAGS_ZF) ? zero  :
        (i==`EFLAGS_AF) ? 0     :
        (i==`EFLAGS_CF) ? 0     :
        (i==`EFLAGS_PF) ? parity: eflags_as_src[i];
    end
  end
  endgenerate
endmodule

module execute_xor (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [`REG_W:0] d_with_bits_maximum =
    (`REG_W+1)'(s)^(`REG_W+1)'(t);

  assign d =
    (bit_mode==`BIT_MODE_8 ) ? `REG_W'(d_with_bits_maximum[ 7:0]):
    (bit_mode==`BIT_MODE_16) ? `REG_W'(d_with_bits_maximum[15:0]):
    (bit_mode==`BIT_MODE_32) ? `REG_W'(d_with_bits_maximum[31:0]):
                               `REG_W'(d_with_bits_maximum[63:0]);
  wire msb =
    (bit_mode==`BIT_MODE_8 ) ? d_with_bits_maximum[ 7]:
    (bit_mode==`BIT_MODE_16) ? d_with_bits_maximum[15]:
    (bit_mode==`BIT_MODE_32) ? d_with_bits_maximum[31]:
                               d_with_bits_maximum[63];
  wire zero =
    (bit_mode==`BIT_MODE_8 ) ? d_with_bits_maximum[ 7:0]== 8'd0:
    (bit_mode==`BIT_MODE_16) ? d_with_bits_maximum[15:0]==16'd0:
    (bit_mode==`BIT_MODE_32) ? d_with_bits_maximum[31:0]==32'd0:
                               d_with_bits_maximum[63:0]==64'd0;
  wire parity =
    (bit_mode==`BIT_MODE_8 ) ? ~(^d_with_bits_maximum[ 7:0]):
    (bit_mode==`BIT_MODE_16) ? ~(^d_with_bits_maximum[15:0]):
    (bit_mode==`BIT_MODE_32) ? ~(^d_with_bits_maximum[31:0]):
                               ~(^d_with_bits_maximum[63:0]);
  genvar i;
  generate
  begin
    for (i=0;i<`REG_W;i=i+1) begin: set_eflags
      assign eflags[i] =
        (i==`EFLAGS_OF) ? 0     :
        (i==`EFLAGS_SF) ? msb   :
        (i==`EFLAGS_ZF) ? zero  :
        (i==`EFLAGS_AF) ? 0     :
        (i==`EFLAGS_CF) ? 0     :
        (i==`EFLAGS_PF) ? parity: eflags_as_src[i];
    end
  end
  endgenerate
endmodule

module execute_sll (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [`REG_W:0] d_with_bits_maximum =
    (`REG_W+1)'(s)<<(`REG_W+1)'(t);

  assign d =
    (bit_mode==`BIT_MODE_8 ) ? `REG_W'(d_with_bits_maximum[ 7:0]):
    (bit_mode==`BIT_MODE_16) ? `REG_W'(d_with_bits_maximum[15:0]):
    (bit_mode==`BIT_MODE_32) ? `REG_W'(d_with_bits_maximum[31:0]):
                               `REG_W'(d_with_bits_maximum[63:0]);
  wire msb =
    (bit_mode==`BIT_MODE_8 ) ? d_with_bits_maximum[ 7]:
    (bit_mode==`BIT_MODE_16) ? d_with_bits_maximum[15]:
    (bit_mode==`BIT_MODE_32) ? d_with_bits_maximum[31]:
                               d_with_bits_maximum[63];
  wire zero =
    (bit_mode==`BIT_MODE_8 ) ? d_with_bits_maximum[ 7:0]== 8'd0:
    (bit_mode==`BIT_MODE_16) ? d_with_bits_maximum[15:0]==16'd0:
    (bit_mode==`BIT_MODE_32) ? d_with_bits_maximum[31:0]==32'd0:
                               d_with_bits_maximum[63:0]==64'd0;
  wire parity =
    (bit_mode==`BIT_MODE_8 ) ? ~(^d_with_bits_maximum[ 7:0]):
    (bit_mode==`BIT_MODE_16) ? ~(^d_with_bits_maximum[15:0]):
    (bit_mode==`BIT_MODE_32) ? ~(^d_with_bits_maximum[31:0]):
                               ~(^d_with_bits_maximum[63:0]);
  genvar i;
  generate
  begin
    for (i=0;i<`REG_W;i=i+1) begin: set_eflags
      assign eflags[i] =
        (i==`EFLAGS_OF) ? 0     :
        (i==`EFLAGS_SF) ? msb   :
        (i==`EFLAGS_ZF) ? zero  :
        (i==`EFLAGS_AF) ? 0     :
        (i==`EFLAGS_CF) ? 0     :
        (i==`EFLAGS_PF) ? parity: eflags_as_src[i];
    end
  end
  endgenerate
endmodule

module execute_mov (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [`REG_W:0] d_with_bits_maximum = (`REG_W+1)'(t);

  assign d =
    (bit_mode==`BIT_MODE_8 ) ? `REG_W'(d_with_bits_maximum[ 7:0]):
    (bit_mode==`BIT_MODE_16) ? `REG_W'(d_with_bits_maximum[15:0]):
    (bit_mode==`BIT_MODE_32) ? `REG_W'(d_with_bits_maximum[31:0]):
                               `REG_W'(d_with_bits_maximum[63:0]);

  assign eflags = eflags_as_src;
endmodule

module execute_cmp (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  assign d = `REG_W'd0;

  // dは必要ないので受け取らない（よしなに最適化されるといいな）
  execute_sub pseudo_sub_1 (
    .eflags       (eflags       ),
    .eflags_as_src(eflags_as_src),
    .s            (s            ),
    .t            (t            ),
    .bit_mode     (bit_mode     )
  );
endmodule

module execute_test (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  assign d = `REG_W'd0;

  // dは必要ないので受け取らない（よしなに最適化されるといいな）
  execute_and pseudo_and_1 (
    .eflags       (eflags       ),
    .eflags_as_src(eflags_as_src),
    .s            (s            ),
    .t            (t            ),
    .bit_mode     (bit_mode     )
  );
endmodule

`default_nettype wire
