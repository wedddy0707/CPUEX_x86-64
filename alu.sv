`default_nettype none
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
  output    reg_t eflags_as_src
);
  genvar i;

  reg_t d[`PRIMITIVE_CALC_N-1:0];
  reg_t e[`PRIMITIVE_CALC_N-1:0];

  miop_t opcode_alu;
  reg_t       s_alu;
  reg_t       t_alu;

  always_comb begin
    case (opcode_alu)
      MIOP_ADD:{d,eflags} <= {d[`PRIMITIVE_CALC_ADD],e[`PRIMITIVE_CALC_ADD]};
      MIOP_AND:{d,eflags} <= {d[`PRIMITIVE_CALC_AND],e[`PRIMITIVE_CALC_AND]};
      MIOP_OR :{d,eflags} <= {d[`PRIMITIVE_CALC_OR ],e[`PRIMITIVE_CALC_OR ]};
      MIOP_XOR:{d,eflags} <= {d[`PRIMITIVE_CALC_XOR],e[`PRIMITIVE_CALC_XOR]};
      MIOP_SLL:{d,eflags} <= {d[`PRIMITIVE_CALC_SLL],e[`PRIMITIVE_CALC_SLL]};
      default :{d,eflags} <=  0;
    endcase

    case (opcode_alu)
      MIOP_ADD: eflags_update <= 1;
      MIOP_AND: eflags_update <= 1;
      default : eflags_update <= 0;
    endcase
  end  
  
  generate
  begin
    for (i=0;i<`PRIMITIVE_CALC_N;i=i+1) begin: generate_primitive_calcs
      primitive_calc #(i) primitive_calc_inst (
        .d            (d[i]         ),
        .eflags       (e[i]         ),
        .eflags_as_src(eflags_as_src),
        .s            (s            ),
        .t            (t            ),
        .bmd          (bmd_alu      )
      );
    end
  end
  endgenerate

  reform_src_in_alu reform_src_in_alu_1 (
    .miinst    (miinst                   ),
    .s         (s                        ),
    .t         (t                        ),
    .cf        (eflags_as_src[`EFLAGS_CF]),
    .opcode_alu(opcode_alu               ),
    .s_alu     (s_alu                    ),
    .t_alu     (t_alu                    )
  );
endmodule

module reform_src_in_alu (
  input  miinst_t miinst    ,
  input     reg_t s         ,
  input     reg_t t         ,
  input     logic cf        ,
  output   miop_t opcode_alu,
  output    reg_t s_alu     ,
  output    reg_t t_alu     ,
  output    bmd_t bmd_alu   //
);
  function reg_t neg (input reg_t x);
  begin
    neg = (~x)+reg_t'(1);
  end
  endfunction

  reg_t imm_sx = reg_t'(  signed'(miinst.imm));
  reg_t imm_zx = reg_t'(unsigned'(miinst.imm));

  always_comb begin
    bmd_alu <= miinst.bmd;

    case (miinst.opcode)
      MIOP_ADDI :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,imm_sx                 };
      MIOP_ADCI :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,imm_sx    +`REG_W'(cf) };
      MIOP_SUBI :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(imm_sx)            };
      MIOP_SBBI :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(imm_sx+`REG_W'(cf))};
      MIOP_MULI :{opcode_alu,s_alu,t_alu}<={MIOP_MUL,s,    imm_sx             };
      MIOP_DIVI :{opcode_alu,s_alu,t_alu}<={MIOP_DIV,s,    imm_sx             };
      MIOP_ANDI :{opcode_alu,s_alu,t_alu}<={MIOP_AND,s,    imm_zx             };
      MIOP_ORI  :{opcode_alu,s_alu,t_alu}<={MIOP_OR ,s,    imm_zx             };
      MIOP_XORI :{opcode_alu,s_alu,t_alu}<={MIOP_XOR,s,    imm_zx             };
      MIOP_SLLI :{opcode_alu,s_alu,t_alu}<={MIOP_SLL,s,    imm_zx             };
      MIOP_SRLI :{opcode_alu,s_alu,t_alu}<={MIOP_SRL,s,    imm_zx             };
      MIOP_SRAI :{opcode_alu,s_alu,t_alu}<={MIOP_SRA,s,    imm_zx             };
      MIOP_MOVI :{opcode_alu,s_alu,t_alu}<={MIOP_OR ,0,    imm_zx             };
      MIOP_CMPI :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(imm_sx)            };
      MIOP_TESTI:{opcode_alu,s_alu,t_alu}<={MIOP_AND,s,    imm_zx             };
      MIOP_ADD  :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,    t                  };
      MIOP_SUB  :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(t)                 };
      MIOP_MUL  :{opcode_alu,s_alu,t_alu}<={MIOP_MUL,s,    t                  };
      MIOP_DIV  :{opcode_alu,s_alu,t_alu}<={MIOP_DIV,s,    t                  };
      MIOP_AND  :{opcode_alu,s_alu,t_alu}<={MIOP_AND,s,    t                  };
      MIOP_OR   :{opcode_alu,s_alu,t_alu}<={MIOP_OR ,s,    t                  };
      MIOP_XOR  :{opcode_alu,s_alu,t_alu}<={MIOP_XOR,s,    t                  };
      MIOP_SLL  :{opcode_alu,s_alu,t_alu}<={MIOP_SLL,s,    t                  };
      MIOP_SRL  :{opcode_alu,s_alu,t_alu}<={MIOP_SRL,s,    t                  };
      MIOP_SRA  :{opcode_alu,s_alu,t_alu}<={MIOP_SRA,s,    t                  };
      MIOP_MOV  :{opcode_alu,s_alu,t_alu}<={MIOP_OR ,0,    t                  };
      MIOP_CMP  :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(t)                 };
      MIOP_TEST :{opcode_alu,s_alu,t_alu}<={MIOP_AND,s,    t                  };
      MIOP_ADC  :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,    t+`REG_W'(cf)      };
      MIOP_SBB  :{opcode_alu,s_alu,t_alu}<={MIOP_ADD,s,neg(t+`REG_W'(cf))     };
      default   :{opcode_alu,s_alu,t_alu}<={miinst.opcode,s,t                 };
    endcase
  end
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
  localparam ARITHMETIC =(CALC==`PRIMITIVE_CALC_ADD);

  logic [`REG_W:0] d_with_bits_maximum;

  generate
  begin
    if      (CALC==`PRIMITIVE_CALC_ADD) begin: calc_add
      assign d_with_bits_maximum = (`REG_W+1)'(signed'(s))+(`REG_W+1)'(signed'(t));
    end
    else if (CALC==`PRIMITIVE_CALC_AND) begin: calc_and
      assign d_with_bits_maximum = (`REG_W+1)'(s)&(`REG_W+1)'(t);
    end
    else if (CALC==`PRIMITIVE_CALC_OR ) begin: calc_or
      assign d_with_bits_maximum = (`REG_W+1)'(s)|(`REG_W+1)'(t);
    end
    else if (CALC==`PRIMITIVE_CALC_XOR) begin: calc_xor
      assign d_with_bits_maximum = (`REG_W+1)'(s)^(`REG_W+1)'(t);
    end
    else if (CALC==`PRIMITIVE_CALC_SLL) begin: calc_sll
      assign d_with_bits_maximum = (`REG_W+1)'(s) << t[5:0];
    end
  end
  endgenerate

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

  assign d =
    (bmd==BMD_08) ? reg_t'(d_with_bits_maximum[ 7:0]):
    (bmd==BMD_16) ? reg_t'(d_with_bits_maximum[15:0]):
    (bmd==BMD_32) ? reg_t'(d_with_bits_maximum[31:0]):
                    reg_t'(d_with_bits_maximum[63:0]);

  wire cf =
    (bmd==BMD_08) ? reg_t'(d_with_bits_maximum[ 8]):
    (bmd==BMD_16) ? reg_t'(d_with_bits_maximum[16]):
    (bmd==BMD_32) ? reg_t'(d_with_bits_maximum[32]):
                    reg_t'(d_with_bits_maximum[64]);

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


`default_nettype wire
