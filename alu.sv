`include "common_params.h"
`include "common_params_svfiles.h"

`define PRIMITIVE_CALC_N   5
`define PRIMITIVE_CALC_ADD 0
`define PRIMITIVE_CALC_AND 1
`define PRIMITIVE_CALC_OR  2
`define PRIMITIVE_CALC_XOR 3
`define PRIMITIVE_CALC_SLL 4

module alu (
  input  miinst_t miinst       ,
  output    reg_t d            ,
  input     reg_t s            ,
  input     reg_t t            ,
  output    reg_t eflags       ,
  output    logic eflags_update,
  input     reg_t eflags_as_src
);
  genvar i;

  reg_t pre_d[`PRIMITIVE_CALC_N-1:0];
  reg_t pre_e[`PRIMITIVE_CALC_N-1:0];

  miop_t  op_alu;
  reg_t    s_alu;
  reg_t    t_alu;
  bmd_t  bmd_alu;

  always_comb begin
    case (op_alu)
      MIOP_ADD:d<=pre_d[`PRIMITIVE_CALC_ADD];
      MIOP_AND:d<=pre_d[`PRIMITIVE_CALC_AND];
      MIOP_OR :d<=pre_d[`PRIMITIVE_CALC_OR ];
      MIOP_XOR:d<=pre_d[`PRIMITIVE_CALC_XOR];
      MIOP_SLL:d<=pre_d[`PRIMITIVE_CALC_SLL];
      default :d<=0;
    endcase
    case (op_alu)
      MIOP_ADD:eflags<=pre_e[`PRIMITIVE_CALC_ADD];
      MIOP_AND:eflags<=pre_e[`PRIMITIVE_CALC_AND];
      MIOP_OR :eflags<=pre_e[`PRIMITIVE_CALC_OR ];
      MIOP_XOR:eflags<=pre_e[`PRIMITIVE_CALC_XOR];
      MIOP_SLL:eflags<=pre_e[`PRIMITIVE_CALC_SLL];
      default :eflags<=0;
    endcase

    case (op_alu)
      MIOP_ADD: eflags_update <= 1;
      MIOP_AND: eflags_update <= 1;
      default : eflags_update <= 0;
    endcase
  end  
  
  generate
  begin
    for (i=0;i<`PRIMITIVE_CALC_N;i=i+1) begin: generate_primitive_calcs
      primitive_calc #(i) primitive_calc_inst (
        .d            (pre_d[i]     ),
        .eflags       (pre_e[i]     ),
        .eflags_as_src(eflags_as_src),
        .s            (s_alu        ),
        .t            (t_alu        ),
        .bmd          (bmd_alu      )
      );
    end
  end
  endgenerate

  reform_src_in_alu reform_src_in_alu_1 (
    .miinst (miinst                   ),
    .s      (s                        ),
    .t      (t                        ),
    .cf     (eflags_as_src[`EFLAGS_CF]),
    .op_alu (op_alu                   ),
    .s_alu  (s_alu                    ),
    .t_alu  (t_alu                    ),
    .bmd_alu(bmd_alu                  )
  );
endmodule

module reform_src_in_alu (
  input  miinst_t miinst ,
  input     reg_t s      ,
  input     reg_t t      ,
  input     logic cf     ,
  output   miop_t op_alu ,
  output    reg_t s_alu  ,
  output    reg_t t_alu  ,
  output    bmd_t bmd_alu//
);
  function reg_t neg (input reg_t x);
  begin
    neg = reg_t'((~x)+reg_t'(1));
  end
  endfunction

  reg_t  imm_sx;
  assign imm_sx = reg_t'(  signed'(miinst.imm));
  reg_t  imm_zx;
  assign imm_zx = reg_t'(unsigned'(miinst.imm));
  reg_t      z;
  assign     z  = reg_t'(0);

  always_comb begin
    bmd_alu <= miinst.bmd;

    case (miinst.op)
      MIOP_ADDI :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,imm_sx                 };
      MIOP_ADCI :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,imm_sx    + reg_t'(cf) };
      MIOP_SUBI :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(imm_sx)            };
      MIOP_SBBI :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(imm_sx+ reg_t'(cf))};
      MIOP_MULI :{op_alu,s_alu,t_alu}<={MIOP_MUL,s,    imm_sx             };
      MIOP_DIVI :{op_alu,s_alu,t_alu}<={MIOP_DIV,s,    imm_sx             };
      MIOP_ANDI :{op_alu,s_alu,t_alu}<={MIOP_AND,s,    imm_zx             };
      MIOP_ORI  :{op_alu,s_alu,t_alu}<={MIOP_OR ,s,    imm_zx             };
      MIOP_XORI :{op_alu,s_alu,t_alu}<={MIOP_XOR,s,    imm_zx             };
      MIOP_SLLI :{op_alu,s_alu,t_alu}<={MIOP_SLL,s,    imm_zx             };
      MIOP_SRLI :{op_alu,s_alu,t_alu}<={MIOP_SRL,s,    imm_zx             };
      MIOP_SRAI :{op_alu,s_alu,t_alu}<={MIOP_SRA,s,    imm_zx             };
      MIOP_MOVI :{op_alu,s_alu,t_alu}<={MIOP_OR ,z,    imm_zx             };
      MIOP_CMPI :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(imm_sx)            };
      MIOP_TESTI:{op_alu,s_alu,t_alu}<={MIOP_AND,s,    imm_zx             };
      MIOP_ADD  :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,    t                  };
      MIOP_SUB  :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(t)                 };
      MIOP_MUL  :{op_alu,s_alu,t_alu}<={MIOP_MUL,s,    t                  };
      MIOP_DIV  :{op_alu,s_alu,t_alu}<={MIOP_DIV,s,    t                  };
      MIOP_AND  :{op_alu,s_alu,t_alu}<={MIOP_AND,s,    t                  };
      MIOP_OR   :{op_alu,s_alu,t_alu}<={MIOP_OR ,s,    t                  };
      MIOP_XOR  :{op_alu,s_alu,t_alu}<={MIOP_XOR,s,    t                  };
      MIOP_SLL  :{op_alu,s_alu,t_alu}<={MIOP_SLL,s,    t                  };
      MIOP_SRL  :{op_alu,s_alu,t_alu}<={MIOP_SRL,s,    t                  };
      MIOP_SRA  :{op_alu,s_alu,t_alu}<={MIOP_SRA,s,    t                  };
      MIOP_MOV  :{op_alu,s_alu,t_alu}<={MIOP_OR ,z,    t                  };
      MIOP_CMP  :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(t)                 };
      MIOP_TEST :{op_alu,s_alu,t_alu}<={MIOP_AND,s,    t                  };
      MIOP_ADC  :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,    t+ reg_t'(cf)      };
      MIOP_SBB  :{op_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(t+ reg_t'(cf))     };
      default   :{op_alu,s_alu,t_alu}<={miinst.op,s,t                     };
    endcase
  end
endmodule

module very_primitive_calc #(
  parameter CALC = `PRIMITIVE_CALC_ADD
) (
  output [`REG_W  :0] d,
  input  [`REG_W-1:0] s,
  input  [`REG_W-1:0] t
);
  function msb (input reg_t x);
  begin
    msb = x[`REG_W-1];
  end
  endfunction

  generate
  begin
    if      (CALC==`PRIMITIVE_CALC_ADD) begin: calc_add
      assign d = signed'({msb(s),s})+signed'({msb(t),t});
    end
    else if (CALC==`PRIMITIVE_CALC_AND) begin: calc_and
      assign d = {1'b0,s}&{1'b0,t};
    end
    else if (CALC==`PRIMITIVE_CALC_OR ) begin: calc_or
      assign d = {1'b0,s}|{1'b0,t};
    end
    else if (CALC==`PRIMITIVE_CALC_XOR) begin: calc_xor
      assign d = {1'b0,s}^{1'b0,t};
    end
    else if (CALC==`PRIMITIVE_CALC_SLL) begin: calc_sll
      assign d = {1'b0,s} << t[5:0];
    end else begin : calc_nop
      assign d = 0;
    end
  end
  endgenerate
endmodule

module primitive_calc #(
  parameter CALC = `PRIMITIVE_CALC_ADD
) (
  output reg_t d            ,
  output reg_t eflags       ,
  input  reg_t eflags_as_src,
  input  reg_t s            ,
  input  reg_t t            ,
  input  bmd_t bmd          //
);
  genvar i;

  localparam ARITHMETIC =(CALC==`PRIMITIVE_CALC_ADD);

  logic [`REG_W:0] d_with_bits_extended;

  very_primitive_calc #(CALC) very_primitive_calc_inst (
    .d (d_with_bits_extended),
    .s (s                   ),
    .t (t                   )
  );

  function logic msb (input reg_t x, input bmd_t b);
  begin
    case (b)
      BMD_08 :msb = x[ 7];
      BMD_16 :msb = x[15];
      BMD_32 :msb = x[31];
      default:msb = x[63];
    endcase
  end
  endfunction

  generate
  begin
    if (ARITHMETIC) begin : sign_extend
      assign d =
        (bmd==BMD_08) ? reg_t'(signed'(d_with_bits_extended[ 7:0])):
        (bmd==BMD_16) ? reg_t'(signed'(d_with_bits_extended[15:0])):
        (bmd==BMD_32) ? reg_t'(signed'(d_with_bits_extended[31:0])):
                        reg_t'(signed'(d_with_bits_extended[63:0]));
    end else begin : zero_extend
      assign d =
        (bmd==BMD_08) ? reg_t'(d_with_bits_extended[ 7:0]):
        (bmd==BMD_16) ? reg_t'(d_with_bits_extended[15:0]):
        (bmd==BMD_32) ? reg_t'(d_with_bits_extended[31:0]):
                        reg_t'(d_with_bits_extended[63:0]);
    end
  end
  endgenerate

  wire cf =
    (bmd==BMD_08) ? reg_t'(d_with_bits_extended[ 8]):
    (bmd==BMD_16) ? reg_t'(d_with_bits_extended[16]):
    (bmd==BMD_32) ? reg_t'(d_with_bits_extended[32]):
                    reg_t'(d_with_bits_extended[64]);

  wire of =( msb(d,bmd)&~msb(s,bmd)&~msb(t,bmd))|
           (~msb(d,bmd)& msb(s,bmd)& msb(t,bmd));
  wire sf =  msb(d,bmd);
  wire zf =~(|d);
  wire pf =~(^d);
  wire af =    0;

  generate
  begin
    for (i=0;i<`REG_W;i=i+1) begin: set_eflags
      if      (i==`EFLAGS_OF && ARITHMETIC) begin : generate_of
        assign eflags[i] = of;
      end
      else if (i==`EFLAGS_SF) begin : generate_sf
        assign eflags[i] = sf;
      end
      else if (i==`EFLAGS_ZF) begin : generate_zf
        assign eflags[i] = zf;
      end
      else if (i==`EFLAGS_AF) begin : generate_af
        assign eflags[i] = af;
      end
      else if (i==`EFLAGS_CF && ARITHMETIC) begin : generate_cf
        assign eflags[i] = cf;
      end
      else if (i==`EFLAGS_PF) begin : generate_pf
        assign eflags[i] = pf;
      end
      else begin : generate_identity
        assign eflags[i] = eflags_as_src[i];
      end
    end
  end
  endgenerate
endmodule
