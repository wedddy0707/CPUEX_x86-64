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
  input wire [`REG_W     -1:0] eflags_as_src
);
  wire [`REG_W-1:0] add_d      ;
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
  wire [`REG_W-1:0] sll_eflags ;
  wire [`REG_W-1:0] and_eflags ;
  wire [`REG_W-1:0]  or_eflags ;
  wire [`REG_W-1:0] xor_eflags ;
  wire [`REG_W-1:0] mov_eflags ;
  wire [`REG_W-1:0] cmp_eflags ;
  wire [`REG_W-1:0] test_eflags;
  wire [`REG_W-1:0] adc_eflags ;
  wire [`REG_W-1:0] sbb_eflags ;

  assign {d,eflags} =
    (opcode==`MICRO_ADD ) ? {add_d,add_eflags}:
    (opcode==`MICRO_ADDI) ? {add_d,add_eflags}:
    (opcode==`MICRO_SUB ) ? {sub_d,sub_eflags}:
    (opcode==`MICRO_SUBI) ? {sub_d,sub_eflags}:
    (opcode==`MICRO_SLLI) ? {sll_d,sll_eflags}:
    (opcode==`MICRO_AND ) ? {and_d,and_eflags}:
    (opcode==`MICRO_ANDI) ? {and_d,and_eflags}:
    (opcode==`MICRO_OR  ) ? { or_d, or_eflags}:
    (opcode==`MICRO_ORI ) ? { or_d, or_eflags}:
    (opcode==`MICRO_XOR ) ? {xor_d,xor_eflags}:
    (opcode==`MICRO_XORI) ? {xor_d,xor_eflags}:
    (opcode==`MICRO_MOV ) ? {mov_d,mov_eflags}:
    (opcode==`MICRO_MOVI) ? {mov_d,mov_eflags}:
    (opcode==`MICRO_ADC ) ? {adc_d,adc_eflags}:
    (opcode==`MICRO_ADCI) ? {adc_d,adc_eflags}:
    (opcode==`MICRO_SBB ) ? {sbb_d,sbb_eflags}:
    (opcode==`MICRO_SBBI) ? {sbb_d,sbb_eflags}: 0;
  
  execute_add add_1 (
    .d            (add_d                      ),
    .s            (s                          ),
    .t            (opcode==`MICRO_ADDI ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (add_eflags                 ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_sub sub_1 (
    .d            (sub_d                      ),
    .s            (s                          ),
    .t            (opcode==`MICRO_SUBI ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (sub_eflags                 ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_sll sll_1 (
    .d            (sll_d                      ),
    .s            (s                          ),
    .t            (opcode==`MICRO_SLLI ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (sll_eflags                 ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_and and_1 (
    .d            (and_d                      ),
    .s            (s                          ),
    .t            (opcode==`MICRO_ANDI ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (and_eflags                 ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_or or_1 (
    .d            (or_d                       ),
    .s            (s                          ),
    .t            (opcode==`MICRO_ORI  ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (or_eflags                  ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_xor xor_1 (
    .d            (xor_d                      ),
    .s            (s                          ),
    .t            (opcode==`MICRO_XORI ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (xor_eflags                 ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_mov mov_1 (
    .d            (mov_d                      ),
    .s            (s                          ),
    .t            (opcode==`MICRO_MOVI ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (mov_eflags                 ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_cmp cmp_1 (
    .d            (cmp_d                      ),
    .s            (s                          ),
    .t            (opcode==`MICRO_CMPI ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (cmp_eflags                 ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_test test_1 (
    .d            (test_d                     ),
    .s            (s                          ),
    .t            (opcode==`MICRO_TESTI ?imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (test_eflags                ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_adc adc_1 (
    .d            (adc_d                      ),
    .s            (s                          ),
    .t            (opcode==`MICRO_ADCI ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (adc_eflags                 ),
    .eflags_as_src(eflags_as_src              )
  );
  execute_sbb sbb_1 (
    .d            (sbb_d                      ),
    .s            (s                          ),
    .t            (opcode==`MICRO_SBBI ? imm:t),
    .bit_mode     (bit_mode                   ),
    .eflags       (sbb_eflags                 ),
    .eflags_as_src(eflags_as_src              )
  );
endmodule

/*************************************
* Operation
*   DEST ← DEST + SRC;
* Flags Affected
*   OF, SF, ZF, AF, CF, and PF flags.
*
*/
module execute_add (
  output reg [`REG_W     -1:0] d            ,
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);

  wire [`REG_W:0] d_with_bits_maximum =
    (`REG_W+1)'(signed'(s))+(`REG_W+1)'(signed'(t));

  wire overflow =
    (bit_mode==`BIT_MODE_8 ) ? (d[ 7]&(~s[ 7])&(~t[ 7]))|((~d[ 7])&s[ 7]&t[ 7]):
    (bit_mode==`BIT_MODE_16) ? (d[15]&(~s[15])&(~t[15]))|((~d[15])&s[15]&t[15]):
    (bit_mode==`BIT_MODE_32) ? (d[31]&(~s[31])&(~t[31]))|((~d[31])&s[31]&t[31]):
                               (d[63]&(~s[63])&(~t[63]))|((~d[63])&s[63]&t[63]);
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
  wire carry =
    (bit_mode==`BIT_MODE_8 ) ? d_with_bits_maximum[ 8]:
    (bit_mode==`BIT_MODE_16) ? d_with_bits_maximum[16]:
    (bit_mode==`BIT_MODE_32) ? d_with_bits_maximum[32]:
                               d_with_bits_maximum[64];
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
        (i==`EFLAGS_OF) ? overflow:
        (i==`EFLAGS_SF) ? msb     :
        (i==`EFLAGS_ZF) ? zero    :
        (i==`EFLAGS_AF) ? 0       :
        (i==`EFLAGS_CF) ? carry   :
        (i==`EFLAGS_PF) ? parity  : eflags_as_src[i];
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
