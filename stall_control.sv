`include "common_params.h"
`include "common_params_svfiles.h"

module stall_control #(
  parameter LOAD_LATENCY = 1,
  parameter POST_DEC_LD  = 3
) (
  input  miinst_t dec_miinst                   ,
  input  miinst_t pos_miinst  [POST_DEC_LD-1:0],
  input     reg_t pos_d       [POST_DEC_LD-1:0],
  output    fwd_t fwd_sig_from[POST_DEC_LD-1:0],
  output    reg_t fwd_val_from[POST_DEC_LD-1:0],
  output    logic stall_phase                  ,
  output    logic stall_pc                     ,
  input     logic out_busy                     ,
  input     logic clk                          ,
  input     logic rstn
);
  localparam LL = LOAD_LATENCY;
  localparam LD = POST_DEC_LD ;
  
  forward_control #(
    POST_DEC_LD
  ) forward_control_1 (
    .*
  );

  wire [LD-1:0] fwd_from            ;
  wire [LD-1:0] load_in             ;
  wire [LD-1:0] stall_due_to_load_in;
  wire          stall_due_to_out    ;

  genvar i;
  generate
  for(i=0;i<LD;i=i+1) begin: generate_0
    assign fwd_from[i] = fwd_sig_from[i].d|fwd_sig_from[i].s|fwd_sig_from[i].t;
  end
  for(i=0;i<LD;i=i+1) begin: generate_1
    assign load_in [i] = (pos_miinst[i].op==MIOP_L);
  end
  for(i=0;i<LD;i=i+1) begin: generate_2
    assign stall_due_to_load_in[i] = load_in[i] & fwd_from[i];
  end
  endgenerate

  assign stall_due_to_out = out_busy;

  assign stall_pc = (|stall_due_to_load_in)|stall_due_to_out;

  echo_assertion #(
    LOAD_LATENCY, 1
  ) echo_assertion_stall (
    .trigger  (stall_pc   ),
    .assertion(stall_phase),
    .clk      (clk        ),
    .rstn     (rstn       )
  );
endmodule
