`default_nettype none
`include "common_params.h"

module execute_set_eflags (
  input wire [`MICRO_W   -1:0] opcode       ,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`IMM_W     -1:0] imm          ,
  input wire [`BIT_MODE_W-1:0] bit_mode     ,
  input wire [`REG_W     -1:0] eflags_as_src,
  output reg [`REG_W     -1:0] eflags
);
  wire [`REG_W-1:0]  cmp_eflags;
  wire [`REG_W-1:0] test_eflags;

  execute_cmp cmp_1 (
    .eflags       (cmp_eflags                 ),
    .eflags_as_src(eflags_as_src              ),
    .s            (s                          ),
    .t            (opcode==`MICRO_CMPI ? imm:t),
    .bit_mode     (bit_mode                   )
  );
endmodule

module execute_cmp (
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire        carry   ;
  wire        overflow;
  wire [63:0] sub_d   ;
  wire msb =
    (bit_mode==`BIT_MODE_8 ) ? sub_d[ 7]:
    (bit_mode==`BIT_MODE_32) ? sub_d[31]:
   /*bit_mode==`BIT_MODE_64*/  sub_d[63];

  execute_sub sub_1 ( // "alu.sv"
    .d        (sub_d   ),
    .carry    (carry   ),
    .overflow (overflow),
    .s        (s       ),
    .t        (t       ),
    .bit_mode (bit_mode)
  );

  genvar i;
  generate
  begin
    for (i=0;i<`REG_W;i=i+1) begin: set_flag
      assign eflags[i] =
        (i==`EFLAGS_CF) ? carry     :
        (i==`EFLAGS_OF) ? overflow  :
        (i==`EFLAGS_PF) ? ~(^sub_d) :
        (i==`EFLAGS_ZF) ? ~(|sub_d) :
        (i==`EFLAGS_SF) ? msb       : eflags_as_src[i];
    end
  end
  endgenerate
endmodule

module execute_test (
  output reg [`REG_W     -1:0] eflags       ,
  input wire [`REG_W     -1:0] eflags_as_src,
  input wire [`REG_W     -1:0] s            ,
  input wire [`REG_W     -1:0] t            ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [63:0] and_d;
  wire msb =
    (bit_mode==`BIT_MODE_8 ) ? and_d[ 7]:
    (bit_mode==`BIT_MODE_32) ? and_d[31]:
   /*bit_mode==`BIT_MODE_64*/  and_d[63];

  execute_and and_1 ( // "alu.sv"
    .d        (and_d   ),
    .s        (s       ),
    .t        (t       ),
    .bit_mode (bit_mode)
  );

  genvar i;
  generate
  begin
    for (i=0;i<`REG_W;i=i+1) begin: set_flag
      assign eflags[i] =
        (i==`EFLAGS_CF) ? 0         :
        (i==`EFLAGS_OF) ? 0         :
        (i==`EFLAGS_PF) ? ~(^and_d) :
        (i==`EFLAGS_ZF) ? ~(|and_d) :
        (i==`EFLAGS_SF) ? msb       : eflags_as_src[i];
    end
  end
  endgenerate
endmodule
`default_nettype wire
