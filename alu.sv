`default_nettype none

module alu (
  output reg [`REG_W     -1:0] d       ,
  input wire [`OPCODE_W  -1:0] opcode  ,
  input wire [`REG_W     -1:0] s       ,
  input wire [`REG_W     -1:0] t       ,
  input wire [`IMM_W     -1:0] imm     ,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [`REG_W-1:0] add_d;
  wire [`REG_W-1:0] sll_d;
  wire [`REG_W-1:0] xor_d;
  wire [`REG_W-1:0] mov_d;
  wire [`REG_W-1:0] lea_d;
  
  assign d =
    (opcode==`MICRO_ADD ) ? add_d :
    (opcode==`MICRO_ADDI) ? add_d :
    (opcode==`MICRO_SLLI) ? sll_d :
    (opcode==`MICRO_XOR ) ? xor_d :
    (opcode==`MICRO_MOV ) ? mov_d :
    (opcode==`MICRO_MOVI) ? mov_d :
    (opcode==`MICRO_LEA ) ? lea_d : 0;
  
  execute_add add_1 (
    .d        (add_d),
    .s        (s),
    .t        (`MICRO_ADDI ? imm:t),
    .bit_mode (bit_mode)
  );
  execute_sll sll_1 (
    .d        (sll_d),
    .s        (s),
    .t        (`MICRO_SLLI ? imm:t),
    .bit_mode (bit_mode)
  );
  execute_xor xor_1 (
    .d        (xor_d),
    .s        (s),
    .t        (t),
    .bit_mode (bit_mode)
  );
  execute_mov mov_1 (
    .d        (mov_d),
    .s        (s),
    .t        (`MICRO_MOVI ? imm:t),
    .bit_mode (bit_mode)
  );
endmodule

module execute_add (
  output reg [`REG_W     -1:0] d,
  output reg                   carry,
  output reg                   overflow,
  input wire [`REG_W     -1:0] s,
  input wire [`REG_W     -1:0] t,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [ 7:0] d_08bit;
  wire [15:0] d_16bit;
  wire [31:0] d_32bit;
  wire [63:0] d_64bit;
  wire        c_08bit;
  wire        c_16bit;
  wire        c_32bit;
  wire        c_64bit;

  assign {c_08bit,d_08bit} =  9'(signed'(s))+ 9'(signed'(t));
  assign {c_16bit,d_16bit} = 17'(signed'(s))+17'(signed'(t));
  assign {c_32bit,d_32bit} = 33'(signed'(s))+33'(signed'(t));
  assign {c_64bit,d_64bit} = 65'(signed'(s))+65'(signed'(t));

  assign d =
    (bit_mode==`BIT_MODE_8 ) ? `REG_W'(signed'(d_08bit)) :
    (bit_mode==`BIT_MODE_16) ? `REG_W'(signed'(d_16bit)) :
    (bit_mode==`BIT_MODE_32) ? `REG_W'(signed'(d_32bit)) : `REG_W'(d_64bit);

  assign carry =
    (bit_mode==`BIT_MODE_8 ) ? c_08bit :
    (bit_mode==`BIT_MODE_16) ? c_16bit :
    (bit_mode==`BIT_MODE_32) ? c_32bit : c_64bit ;

  // 負=正+正 or 正=負+負
  assign overflow =
    (bit_mode==`BIT_MODE_8 ) ? (d[ 7]&(~s[ 7])&(~t[ 7]))|((~d[ 7])&s[ 7]&t[ 7]) :
    (bit_mode==`BIT_MODE_16) ? (d[15]&(~s[15])&(~t[15]))|((~d[15])&s[15]&t[15]) :
    (bit_mode==`BIT_MODE_32) ? (d[31]&(~s[31])&(~t[31]))|((~d[31])&s[31]&t[31]) :
                               (d[63]&(~s[63])&(~t[63]))|((~d[63])&s[63]&t[63]) ;
endmodule

module execute_sub (
  output reg [`REG_W     -1:0] d,
  output reg                   carry,
  output reg                   overflow,
  input wire [`REG_W     -1:0] s,
  input wire [`REG_W     -1:0] t,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  execute_add add_1 (
    .d        (d),
    .carry    (carry),
    .overflow (overflow),
    .s        (s),
    .t        (~t+1),
    .bit_mode (bit_mode)
  );
endmodule

module execute_xor (
  output reg [`REG_W     -1:0] d,
  input wire [`REG_W     -1:0] s,
  input wire [`REG_W     -1:0] t,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [ 7:0] d_08bit =  8'(s) ^  8'(t);
  wire [15:0] d_16bit = 16'(s) ^ 16'(t);
  wire [31:0] d_32bit = 32'(s) ^ 32'(t);
  wire [63:0] d_64bit = 64'(s) ^ 64'(t);

  assign d =
    (bit_mode==`BIT_MODE_8 ) ? `REG_W'(d_08bit) :
    (bit_mode==`BIT_MODE_16) ? `REG_W'(d_16bit) :
    (bit_mode==`BIT_MODE_32) ? `REG_W'(d_32bit) : `REG_W'(d_64bit);
endmodule

module execute_sll (
  output reg [`REG_W     -1:0] d,
  input wire [`REG_W     -1:0] s,
  input wire [`REG_W     -1:0] t,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [ 7:0] d_08bit =  8'(s) <<  8'(t);
  wire [15:0] d_16bit = 16'(s) << 16'(t);
  wire [31:0] d_32bit = 32'(s) << 32'(t);
  wire [63:0] d_64bit = 64'(s) << 64'(t);

  assign d =
    (bit_mode==`BIT_MODE_8 ) ? `REG_W'(d_08bit) :
    (bit_mode==`BIT_MODE_16) ? `REG_W'(d_16bit) :
    (bit_mode==`BIT_MODE_32) ? `REG_W'(d_32bit) : `REG_W'(d_64bit);
endmodule

module execute_mov (
  output reg [`REG_W     -1:0] d,
  input wire [`REG_W     -1:0] s,
  input wire [`REG_W     -1:0] t,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire [ 7:0] d_08bit =  8'(t);
  wire [15:0] d_16bit = 16'(t);
  wire [31:0] d_32bit = 32'(t);
  wire [63:0] d_64bit = 64'(t);

  assign d =
    (bit_mode==`BIT_MODE_8 ) ? `REG_W'(d_08bit) :
    (bit_mode==`BIT_MODE_16) ? `REG_W'(d_16bit) :
    (bit_mode==`BIT_MODE_32) ? `REG_W'(d_32bit) : `REG_W'(d_64bit);
endmodule

module execute_cmp (
  output reg [`REG_W     -1:0] d,
  input wire [`REG_W     -1:0] s,
  input wire [`REG_W     -1:0] t,
  input wire [`BIT_MODE_W-1:0] bit_mode
);
  wire        carry;
  wire        overflow;
  wire [63:0] sub_d;

  execute_sub sub_1 (
    .d        (sub_d),
    .carry    (carry),
    .overflow (overflow),
    .s        (s),
    .t        (t),
    .bit_mode (bit_mode)
  );

  genvar i;
  generate
  begin
    for (i=0;i<`REG_W;i=i+1) begin: set_flag
      assign d[i] =
        (i==`EFLAGS_CF) ? carry            :
        (i==`EFLAGS_OF) ? overflow         :
        (i==`EFLAGS_PF) ? ~(^sub_d)        :
        (i==`EFLAGS_ZF) ? ~(|sub_d)        :
        (i==`EFLAGS_SF) ? signed'(sub_d)<0 : 0;
    end
  end
  endgenerate
endmodule

`default_nettype wire
