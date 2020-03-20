`include "common_params.h"
`include "common_params_svfiles.h"

module decode_phase #(
  parameter POST_DEC_LD = 3
) (
  input  miinst_t deq_miinst_head              ,
  output de_reg_t de_reg                       ,
  input  reg_t    gpr         [`REG_N     -1:0],
  input  fwd_t    fwd_sig_from[POST_DEC_LD-1:0],
  input  reg_t    fwd_val_from[POST_DEC_LD-1:0],
  input  logic    stall                        ,
  input  logic    flush                        ,
  input  logic    clk                          ,
  input  logic    rstn
);
  reg_t dec_d;
  reg_t dec_s;
  reg_t dec_t;

  always @(posedge clk) begin
    de_reg.miinst <= (~rstn|flush|stall) ? nop(0):deq_miinst_head;
    de_reg.d      <= (~rstn|flush|stall) ?     0 :dec_d;
    de_reg.s      <= (~rstn|flush|stall) ?     0 :dec_s;
    de_reg.t      <= (~rstn|flush|stall) ?     0 :dec_t;
  end
  
  decode_phase_value_decision #(
    POST_DEC_LD
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
      assign val_iter_d[i] = (fwd_sig_from[i].d) ? fwd_val_from[i] : val_iter_d[i+1];
    end
    for(i=LD-1;i>=0;i=i-1) begin: iter_s
      assign val_iter_s[i] = (fwd_sig_from[i].s) ? fwd_val_from[i] : val_iter_s[i+1];
    end
    for(i=LD-1;i>=0;i=i-1) begin: iter_t
      assign val_iter_t[i] = (fwd_sig_from[i].t) ? fwd_val_from[i] : val_iter_t[i+1];
    end
  end
  endgenerate

  assign d = (miinst.d==RIP) ? reg_t'(miinst.pc+1):val_iter_d[0];
  assign s = (miinst.s==RIP) ? reg_t'(miinst.pc+1):val_iter_s[0];
  assign t = (miinst.t==RIP) ? reg_t'(miinst.pc+1):val_iter_t[0];

endmodule
