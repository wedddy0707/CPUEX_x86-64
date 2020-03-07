`default_nettype none
`include "common_params.h"
`include "common_params_svfiles.h"

module decode_phase #(
  parameter POST_DEC_LD = 3
) (
  input  miinst_t deq_miinst_head              ,
  output miinst_t de_miinst                    ,
  output reg_t    de_d                         ,
  output reg_t    de_s                         ,
  output reg_t    de_t                         ,
  input  reg_t    gpr         [`REG_N     -1:0],
  input  fws_t    fwd_sig_from[POST_DEC_LD-1:0],
  input  reg_t    fwd_val_from[POST_DEC_LD-1:0],
  input  logic    stall                        ,
  input  logic    flush                        ,
  input  logic    clk                          ,
  input  logic    rstn
);
  wire [`REG_W-1:0] dec_d;
  wire [`REG_W-1:0] dec_s;
  wire [`REG_W-1:0] dec_t;

  miint_t nop;
  assign nop.opcode = MIOP_NOP;

  always @(posedge clk) begin
    de_miinst <= (~rstn|flush|stall) ? nop:deq_miinst_head;
    de_d      <= (~rstn|flush|stall) ?   0:dec_d;
    de_s      <= (~rstn|flush|stall) ?   0:dec_s;
    de_t      <= (~rstn|flush|stall) ?   0:dec_t;
  end
  
  decode_phase_value_decision #(
    EW_LAYER
  ) decode_phase_value_decision_1 (
    .miinst      (deq_miinst_head),
    .gpr         (gpr            ),
    .fwd_sig_from(fwd_sig_from   ),
    .fwd_val_from(fwd_val_from   ),
    .d           (dec_d          ),
    .s           (dec_s          ),
    .t           (dec_t          )
  );
endmodule


module decode_phase_value_decision #(
  parameter POST_DEC_LD = 3
) (
  input  miinst_t miinst                       ,
  input  reg_t    gpr         [`REG_N     -1:0],
  input  fwd_t    fwd_sig_from[POST_DEC_LD-1:0],
  input  reg_t    fwd_val_from[POST_DEC_LD-1:0],
  output reg_t    d                            ,
  output reg_t    s                            ,
  output reg_t    t
);
  localparam LD = POST_DEC_LD;
  reg_t val_iter_d [LD:0];
  reg_t val_iter_s [LD:0];
  reg_t val_iter_t [LD:0];

  assign val_iter_d[LD] = gpr[miinst.d];
  assign val_iter_s[LD] = gpr[miinst.s];
  assign val_iter_t[LD] = gpr[miinst.t];
  genvar i;
  generate
  begin
    for(i=LD-1;i>=0;i=i-1) begin: iter_d
      assign val_iter_d[i] = (fwd_sig_from[i].d) ? fwd_val_from[i] : val_iter[i+1];
    end
    for(i=LD-1;i>=0;i=i-1) begin: iter_s
      assign val_iter_s[i] = (fwd_sig_from[i].s) ? fwd_val_from[i] : val_iter[i+1];
    end
    for(i=LD-1;i>=0;i=i-1) begin: iter_t
      assign val_iter_t[i] = (fwd_sig_from[i].t) ? fwd_val_from[i] : val_iter[i+1];
    end
  end
  endgenerate

  assign d = (miinst.d==`RIP_ADDR) ? reg_t'(miinst.pc+1):val_iter_d[0];
  assign s = (miinst.s==`RIP_ADDR) ? reg_t'(miinst.pc+1):val_iter_s[0];
  assign t = (miinst.t==`RIP_ADDR) ? reg_t'(miinst.pc+1):val_iter_t[0];

endmodule


`default_nettype wire
