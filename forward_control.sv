`default_nettype none
`include "common_params.h"

module forward_control #(
  parameter EW_LAYER = 1
)(
  input  wire [`OPCODE_W  -1:0] dec_opcode              ,
  input  wire [`REG_ADDR_W-1:0] dec_rd_addr             ,
  input  wire [`REG_ADDR_W-1:0] dec_rs_addr             ,
  input  wire [`REG_ADDR_W-1:0] dec_rt_addr             ,
  input  wire [`OPCODE_W  -1:0] exe_opcode              ,
  input  wire [`REG_ADDR_W-1:0] exe_rd_addr             ,
  input  wire [`OPCODE_W  -1:0] wri_opcode  [EW_LAYER:0],
  input  wire [`REG_ADDR_W-1:0] wri_rd_addr [EW_LAYER:0],
  output wire                   forward_to_d_from_exe   ,
  output wire                   forward_to_s_from_exe   ,
  output wire                   forward_to_t_from_exe   ,
  output wire [EW_LAYER     :0] forward_to_d_from_wri   ,
  output wire [EW_LAYER     :0] forward_to_s_from_wri   ,
  output wire [EW_LAYER     :0] forward_to_t_from_wri   //
);
  localparam EL = EW_LAYER;

  wire        dec_from_gd, dec_from_fd;
  wire        dec_from_gs, dec_from_fs;
  wire        dec_from_gt, dec_from_ft;
  wire        exe_to_gd,   exe_to_fd;
  wire        dec_to_gd,   dec_to_fd;
  wire [EL:0] wri_to_gd,   wri_to_fd;

  register_usage_table rut_dec (
    .opcode     (dec_opcode),
    .d_from_gpr (dec_from_gd),
    .d_from_fpr (dec_from_fd),
    .s_from_gpr (dec_from_gs),
    .s_from_fpr (dec_from_fs),
    .t_from_gpr (dec_from_gt),
    .t_from_fpr (dec_from_ft)
  );

  register_usage_table rut_exe (
    .opcode   (exe_opcode),
    .d_to_gpr (exe_to_gd),
    .d_to_fpr (exe_to_fd)
  );

  forward_necessity fn_exe_d (
    .target_reg_addr  (dec_rd_addr),
    .target_from_g    (dec_from_gd),
    .target_from_f    (dec_from_fd),
    .source_reg_addr  (exe_rd_addr),
    .source_to_g      (exe_to_gd),
    .source_to_f      (exe_to_fd),
    .forward          (forward_to_d_from_exe)
  );
  
  forward_necessity fn_exe_s (
    .target_reg_addr  (dec_rs_addr),
    .target_from_g    (dec_from_gs),
    .target_from_f    (dec_from_fs),
    .source_reg_addr  (exe_rd_addr),
    .source_to_g      (exe_to_gd),
    .source_to_f      (exe_to_fd),
    .forward          (forward_to_s_from_exe)
  );
  
  forward_necessity fn_exe_t (
    .target_reg_addr  (dec_rt_addr),
    .target_from_g    (dec_from_gt),
    .target_from_f    (dec_from_ft),
    .source_reg_addr  (exe_rd_addr),
    .source_to_g      (exe_to_gd),
    .source_to_f      (exe_to_fd),
    .forward          (forward_to_t_from_exe)
  );
  
  genvar a,b,c,d;
  generate
  for(a=0;a<EL+1;a=a+1) begin: gen_table
    register_usage_table rut_wri (
      .opcode   (wri_opcode[a]),
      .d_to_gpr (wri_to_gd [a]),
      .d_to_fpr (wri_to_fd [a])
    );
  end
  for(b=0;b<EL+1;b=b+1) begin: gen_d
    forward_necessity fn_wri_d (
      .target_reg_addr  (dec_rd_addr),
      .target_from_g    (dec_from_gd),
      .target_from_f    (dec_from_fd),
      .source_reg_addr  (wri_rd_addr[b]),
      .source_to_g      (wri_to_gd  [b]),
      .source_to_f      (wri_to_fd  [b]),
      .forward          (forward_to_d_from_wri[b])
    );
  end
  for(c=0;c<EL+1;c=c+1) begin: gen_s
    forward_necessity fn_wri_s (
      .target_reg_addr  (dec_rs_addr),
      .target_from_g    (dec_from_gs),
      .target_from_f    (dec_from_fs),
      .source_reg_addr  (wri_rd_addr[c]),
      .source_to_g      (wri_to_gd  [c]),
      .source_to_f      (wri_to_fd  [c]),
      .forward          (forward_to_s_from_wri[c])
    );
  end
  for(d=0;d<EL+1;d=d+1) begin: gen_t
    forward_necessity fn_wri_t (
      .target_reg_addr  (dec_rt_addr),
      .target_from_g    (dec_from_gt),
      .target_from_f    (dec_from_ft),
      .source_reg_addr  (wri_rd_addr[d]),
      .source_to_g      (wri_to_gd  [d]),
      .source_to_f      (wri_to_fd  [d]),
      .forward          (forward_to_t_from_wri[d])
    );
  end
  endgenerate
endmodule

module forward_necessity (
  input  wire [`REG_ADDR_W-1:0] target_reg_addr,
  input  wire                   target_from_g,
  input  wire                   target_from_f,
  input  wire [`REG_ADDR_W-1:0] source_reg_addr,
  input  wire                   source_to_g,
  input  wire                   source_to_f,
  output wire                   forward
);
  assign forward =
    (target_reg_addr==source_reg_addr) &
    ((target_from_g&source_to_g)|(target_from_f&source_to_f));
endmodule



`default_nettype wire
