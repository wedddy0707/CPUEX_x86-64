`include "common_params.h"
`include "common_params_svfiles.h"

module execute_phase #(
  parameter LOAD_LATENCY = 1,
  parameter POST_DEC_LD  = 4
) (
  input  de_reg_t de_reg                     ,
  input     reg_t gpr[`REG_N-1:0]            ,
  output ew_reg_t ew_reg                     ,
  output ew_sig_t ew_sig                     ,
  output miinst_t pos_miinst[POST_DEC_LD-1:0],
  output    reg_t pos_d     [POST_DEC_LD-1:0],
  output   addr_t mem_addr                   ,
  output    reg_t st_data                    ,
  output logic[7:0] we                       ,
  input     reg_t ld_data                    ,
  input     logic clk                        ,
  input     logic rstn                       //
);
  localparam LL   = LOAD_LATENCY ;
  localparam LD   = POST_DEC_LD  ;
  localparam EQ_N = POST_DEC_LD-1;

  miinst_t    exq_miinst   [EQ_N-1:0];
  reg_t       exq_d        [EQ_N-1:0];
  logic [2:0] exq_ld_offset[EQ_N-1:0];

  logic [2:0] ld_offset;

  assign ew_reg.miinst      = exq_miinst[EQ_N-1];
  assign ew_reg.d           = exq_d     [EQ_N-1];
  assign pos_miinst[0]      = de_reg.miinst;
  assign pos_d     [0]      = ew_sig.d     ;
  assign pos_miinst[LD-1:1] = exq_miinst   ;
  assign pos_d     [LD-1:1] = exq_d        ;
  
  reg_t  ld_data_to_write;
  assign ld_data_to_write =
    (exq_ld_offset[LL]==3'd0) ? reg_t'(ld_data[`REG_W-1: 0]):
    (exq_ld_offset[LL]==3'd1) ? reg_t'(ld_data[`REG_W-1: 8]):
    (exq_ld_offset[LL]==3'd2) ? reg_t'(ld_data[`REG_W-1:16]):
    (exq_ld_offset[LL]==3'd3) ? reg_t'(ld_data[`REG_W-1:24]):
    (exq_ld_offset[LL]==3'd4) ? reg_t'(ld_data[`REG_W-1:32]):
    (exq_ld_offset[LL]==3'd5) ? reg_t'(ld_data[`REG_W-1:40]):
    (exq_ld_offset[LL]==3'd6) ? reg_t'(ld_data[`REG_W-1:48]):
                                reg_t'(ld_data[`REG_W-1:56]);

  integer i;
  always @(posedge clk) begin
    exq_d        [0] <= ~rstn ? 0      : ew_sig.d     ;
    exq_miinst   [0] <= ~rstn ? nop(0) : de_reg.miinst;
    exq_ld_offset[0] <= ~rstn ? 0      : ld_offset    ;
    
    for(i=1;i<EQ_N;i=i+1) begin
      exq_miinst   [i] <= ~rstn ? nop(0):exq_miinst   [i-1];
      exq_ld_offset[i] <= ~rstn ?     0 :exq_ld_offset[i-1];

      if (i==LOAD_LATENCY+1 && exq_miinst[i-1].op==MIOP_L) begin
        case (exq_miinst[i-1].bmd)
          BMD_08 : exq_d[i] <= reg_t'(ld_data_to_write[ 7:0]);
          BMD_32 : exq_d[i] <= reg_t'(ld_data_to_write[31:0]);
          default: exq_d[i] <= reg_t'(ld_data_to_write[63:0]);
        endcase
      end else begin
        exq_d[i] <= exq_d[i-1];
      end
    end
  end

  alu alu_1 (
    .miinst       (de_reg.miinst       ),
    .d            (ew_sig.d            ),
    .s            (de_reg.s            ),
    .t            (de_reg.t            ),
    .eflags       (ew_sig.eflags       ),
    .eflags_update(ew_sig.eflags_update),
    .eflags_as_src(gpr[EFL]            )
  );

  execute_memory_access mem_1 (
    .miinst   (de_reg.miinst),
    .d        (de_reg.d     ),
    .s        (de_reg.s     ),
    .t        (de_reg.t     ),
    .mem_addr (mem_addr     ),
    .st_data  (st_data      ),
    .we       (we           ),
    .ld_offset(ld_offset    ),
    .clk      (clk          ),
    .rstn     (rstn         )
  );
  execute_branch br_1 (
    .miinst          (de_reg.miinst ),
    .d               (de_reg.d      ),
    .eflags          (gpr[EFL]      ),
    .rcx             (gpr[RCX]      ),
    .branch_direction(ew_sig.bd     ),
    .branch_enable   (ew_sig.be     )
  );
endmodule

module execute_memory_access #(
  parameter IO_FILE_POINTER = 32'hfffff000
) (
  input miinst_t       miinst   ,
  input    reg_t       d        ,
  input    reg_t       s        ,
  input    reg_t       t        ,
  output  addr_t       mem_addr ,
  output   reg_t       st_data  ,
  output   logic [7:0] we       ,
  output   logic [2:0] ld_offset,
  input    logic       clk      ,
  input    logic       rstn
);

  addr_t a;
  assign a = addr_t'(signed'({1'b0,s})+(`ADDR_W+1)'signed'(miinst.imm));

  always @(posedge clk) begin
    if (~rstn) begin
      we <= 0;
    end else begin
      mem_addr  <= addr_t'(a[`ADDR_W-1:3]);
      st_data   <=  reg_t'(d << {a[2:0],3'b000});
      we        <=
        (miinst.op  !=MIOP_S) ? 8'h00          :
        (miinst.bmd ==BMD_08) ? 8'h01 << a[2:0]:
        (miinst.bmd ==BMD_32) ? 8'h0f << a[2:0]:
        (miinst.bmd ==BMD_64) ? 8'hff          : 8'h00;
    end
  end
endmodule

module execute_branch (
  input   miinst_t miinst          ,
  input      reg_t d               ,
  input      reg_t eflags          ,
  input      reg_t rcx             ,
  output    addr_t branch_direction,
  output     logic branch_enable   //
);
  wire above   ,
       below   ,
       carry   ,
       equal   ,
       greater ,
       less    ,
       overflow,
       parity  ,
       sign    ;
  
  assign branch_enable =
    // 無条件分岐
    (miinst.op==MIOP_J  ) ?  1              :
    (miinst.op==MIOP_JR ) ?  1              :
    // 条件分岐 Jcc
    (miinst.op==MIOP_JA ) ?  above          :
    (miinst.op==MIOP_JAE) ?  above   | equal:
    (miinst.op==MIOP_JB ) ?  below          :
    (miinst.op==MIOP_JBE) ?  below   | equal:
    (miinst.op==MIOP_JC ) ?  carry          :
    (miinst.op==MIOP_JE ) ?  equal          :
    (miinst.op==MIOP_JG ) ?  greater        :
    (miinst.op==MIOP_JGE) ?  greater | equal:
    (miinst.op==MIOP_JL ) ?  less           :
    (miinst.op==MIOP_JLE) ?  less    | equal:
    (miinst.op==MIOP_JO ) ?  overflow       :
    (miinst.op==MIOP_JP ) ?  parity         :
    (miinst.op==MIOP_JS ) ?  sign           :
    (miinst.op==MIOP_JNE) ? ~equal          :
    (miinst.op==MIOP_JNP) ? ~parity         :
    (miinst.op==MIOP_JNS) ? ~sign           :
    (miinst.op==MIOP_JNO) ? ~overflow       :
    // 条件分岐 JCX
    (miinst.op==MIOP_JCX) ?  (
    (miinst.bmd==BMD_32) ? ~|rcx[31:0]:
    /*         ==BMD_64 */ ~|rcx[63:0]
    )                                           : 0;

  addr_t type_reg;
  assign type_reg = addr_t'(d);
  addr_t type_rel;
  assign type_rel = miinst.pc + addr_t'(signed'(miinst.imm))+addr_t'(1);
  
  assign branch_direction =
    // 無条件分岐
    (miinst.op==MIOP_J  ) ? type_rel :
    (miinst.op==MIOP_JR ) ? type_reg :
    // 条件分岐 Jcc
    (miinst.op==MIOP_JA ) ? type_rel :
    (miinst.op==MIOP_JAE) ? type_rel :
    (miinst.op==MIOP_JB ) ? type_rel :
    (miinst.op==MIOP_JBE) ? type_rel :
    (miinst.op==MIOP_JC ) ? type_rel :
    (miinst.op==MIOP_JE ) ? type_rel :
    (miinst.op==MIOP_JG ) ? type_rel :
    (miinst.op==MIOP_JG ) ? type_rel :
    (miinst.op==MIOP_JL ) ? type_rel :
    (miinst.op==MIOP_JLE) ? type_rel :
    (miinst.op==MIOP_JO ) ? type_rel :
    (miinst.op==MIOP_JP ) ? type_rel :
    (miinst.op==MIOP_JS ) ? type_rel :
    (miinst.op==MIOP_JNE) ? type_rel :
    (miinst.op==MIOP_JNP) ? type_rel :
    (miinst.op==MIOP_JNS) ? type_rel :
    (miinst.op==MIOP_JNO) ? type_rel :
    // 条件分岐 JCX
    (miinst.op==MIOP_JCX) ? type_rel : 0;

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
