`include "common_params.h"
`include "common_params_svfiles.h"

module forward_control #(
  parameter POST_DEC_LD = 3 // POST-DECode-phase Layer Depthのつもり
)(
  input  miinst_t dec_miinst                   ,
  input  miinst_t pos_miinst  [POST_DEC_LD-1:0],
  input     reg_t pos_d       [POST_DEC_LD-1:0],
  output    fwd_t fwd_sig_from[POST_DEC_LD-1:0], 
  output    reg_t fwd_val_from[POST_DEC_LD-1:0]
);
  localparam LD = POST_DEC_LD;
  
  /***********************************
  * Set fwd_val_from.
  */
  assign fwd_val_from = pos_d;

  /***********************************
  * Set fwd_sig_from.
  */
  rut_t dec_rut;
  rut_t pos_rut[LD-1:0];

  register_usage_table rut_dec (
    .miinst(dec_miinst),
    .rut   (dec_rut)
  );

  genvar i;
  generate
  begin
    for(i=0;i<LD;i=i+1) begin: gen_table
      register_usage_table rut_wri (
        .miinst(pos_miinst[i]),
        .rut   (pos_rut[i])
      );
    end
    for(i=0;i<LD;i=i+1) begin: gen_d
      assign fwd_sig_from[i].d=(dec_rut.d==pos_rut[i].d)&((dec_rut.from_gd&pos_rut[i].to_gd)|(dec_rut.from_fd&pos_rut[i].to_fd));
    end
    for(i=0;i<LD;i=i+1) begin: gen_s
      assign fwd_sig_from[i].s=(dec_rut.s==pos_rut[i].d)&((dec_rut.from_gs&pos_rut[i].to_gd)|(dec_rut.from_fs&pos_rut[i].to_fd));
    end
    for(i=0;i<LD;i=i+1) begin: gen_t
      assign fwd_sig_from[i].t=(dec_rut.t==pos_rut[i].d)&((dec_rut.from_gt&pos_rut[i].to_gd)|(dec_rut.from_ft&pos_rut[i].to_fd));
    end
  end
  endgenerate
endmodule
