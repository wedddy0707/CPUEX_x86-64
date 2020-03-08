`default_nettype none
`include "common_params.h"

module core #(
  parameter LOAD_LATEMCY = 1,
  parameter INIT_RIP     = 0,
  parameter INIT_RSP     = 1024
) (
  input wire [`DATA_W  -1:0] ld_data_for_inst,
  input wire [`DATA_W  -1:0] ld_data,
  output reg [`DATA_W  -1:0] st_data,
  output reg [`ADDR_W  -1:0] mem_addr,
  output reg [`ADDR_W  -1:0] pc_to_mem,
  output reg [`DATA_W/8-1:0] we,
  input wire                 clk,
  input wire                 rstn
);
  localparam POST_DEC_LD = LOAD_LATEMCY+2;

  inst_t inst =
    (pc_to_fet[2:0]==3'b111) ? ld_data_for_inst[ 7: 0] :
    (pc_to_fet[2:0]==3'b110) ? ld_data_for_inst[15: 8] :
    (pc_to_fet[2:0]==3'b101) ? ld_data_for_inst[23:16] :
    (pc_to_fet[2:0]==3'b100) ? ld_data_for_inst[31:24] :
    (pc_to_fet[2:0]==3'b011) ? ld_data_for_inst[39:32] :
    (pc_to_fet[2:0]==3'b010) ? ld_data_for_inst[47:40] :
    (pc_to_fet[2:0]==3'b001) ? ld_data_for_inst[55:48] :
                               ld_data_for_inst[63:56] ;

  miinst_t fet_miinst [`MQ_N-1:0];
  logic    fet_valid             ;
  miinst_t deq_miinst_head       ;
  de_reg_t de_reg;
  ew_sig_t ew_sig;
  ew_reg_t ew_reg;
  miinst_t pos_miinst[POST_DEC_LD-1:0];
  reg_t    pos_d     [POST_DEC_LD-1:0];
  reg_t    gpr       [`REG_N     -1:0];
  addr_t   pc_to_fet;
  fwd_t    fwd_sig_from[POST_DEC_LD-1:0];
  reg_t    fwd_sig_from[POST_DEC_LD-1:0];
  logic    stall_phase;
  logic    stall_pc;

  fetch_phase fetch_phase_1 (
    .inst  (inst       ),
    .pc    (pc_to_fet  ),
    .miinst(fet_miinst ),
    .valid (fet_valid  ),
    .stall (stall_phase),
    .flush (flush      ),
    .clk   (clk        ),
    .rstn  (rstn       )
  );

  decode_queue decode_queue_1 (
    .fet_miinst     (fet_miinst     ),
    .fet_valid      (fet_valid      ),
    .deq_miinst_head(deq_miinst_head),
    .stall          (stall_phase    ),
    .flush          (flush          ),
    .clk            (clk            ),
    .rstn           (rstn           )
  );

  decode_phase #(
    EW_LAYER
  ) decode_phase_1 (
    .deq_miinst_head(deq_miinst_head),
    .de_reg         (de_reg         ),
    .gpr            (gpr            ),
    .fwd_sig_from   (fwd_sig_from   ),
    .fwd_val_from   (fwd_val_from   ),
    .stall          (stall_phase    ),
    .flush          (flush          ),
    .clk            (clk            ),
    .rstn           (rstn           )
  );

  execute_phase #(
    LOAD_LATEMCY
  ) execute_phase_1 (
    .de_reg    (de_reg    ),
    .gpr       (gpr       ),
    .ew_sig    (ew_sig    ),
    .ew_reg    (ew_reg    ),
    .pos_miinst(pos_miinst),
    .pos_d     (pos_d     ),
    .mem_addr  (mem_addr  ),
    .st_data   (st_data   ),
    .we        (we        ),
    .clk       (clk       ),
    .rstn      (rstn      )
  );

  write_back_phase #(
    LOAD_LATEMCY
  ) write_back_phase_1 (
    .ew_reg   (ew_reg   ),
    .ew_sig   (ew_sig   ),
    .gpr      (gpr      ),
    .pc_to_mem(pc_to_mem),
    .pc_to_fet(pc_to_fet),
    .stall_pc (stall_pc ),
    .flush    (flush    ),
    .clk      (clk      ),
    .rstn     (rstn     )
  );

  stall_control #(
    LOAD_LATEMCY,
    EW_LAYER
  ) stall_control_1 (
    .dec_miinst   (deq_miinst_head),
    .pos_miinst   (pos_miinst     ),
    .pos_d        (pos_d          ),
    .fwd_sig_from (fwd_sig_from   ),
    .fwd_val_from (fwd_val_from   ),
    .stall_phase  (stall_phase    ),
    .stall_pc     (stall_pc       ),
    .clk          (clk            ),
    .rstn         (rstn           )
  );
endmodule

`default_nettype wire
