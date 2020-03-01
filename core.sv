`default_nettype none
`include "common_params.h"

module core #(
  parameter LOAD_LATEMCY = 1
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
  localparam EW_LAYER = LOAD_LATEMCY+1;

  wire [`INST_W    -1:0] inst =
    (pc_to_fet[2:0]==3'b111) ? ld_data_for_inst[ 7: 0] :
    (pc_to_fet[2:0]==3'b110) ? ld_data_for_inst[15: 8] :
    (pc_to_fet[2:0]==3'b101) ? ld_data_for_inst[23:16] :
    (pc_to_fet[2:0]==3'b100) ? ld_data_for_inst[31:24] :
    (pc_to_fet[2:0]==3'b011) ? ld_data_for_inst[39:32] :
    (pc_to_fet[2:0]==3'b010) ? ld_data_for_inst[47:40] :
    (pc_to_fet[2:0]==3'b001) ? ld_data_for_inst[55:48] :
                               ld_data_for_inst[63:56] ;

  wire [`MICRO_W   -1:0] fet_opcode       [`MICRO_Q_N-1:0];
  wire [`REG_ADDR_W-1:0] fet_reg_addr_d   [`MICRO_Q_N-1:0];
  wire [`REG_ADDR_W-1:0] fet_reg_addr_s   [`MICRO_Q_N-1:0];
  wire [`REG_ADDR_W-1:0] fet_reg_addr_t   [`MICRO_Q_N-1:0];
  wire [`IMM_W     -1:0] fet_immediate    [`MICRO_Q_N-1:0];
  wire [`DISP_W    -1:0] fet_displacement [`MICRO_Q_N-1:0];
  wire [`BIT_MODE_W-1:0] fet_bit_mode     [`MICRO_Q_N-1:0];
  wire [`ADDR_W    -1:0] fet_pc           [`MICRO_Q_N-1:0];
  wire                   fet_inst_valid                   ;
  wire [`MICRO_W   -1:0] deq_opcode_head                  ;
  wire [`REG_ADDR_W-1:0] deq_reg_addr_d_head              ;
  wire [`REG_ADDR_W-1:0] deq_reg_addr_s_head              ;
  wire [`REG_ADDR_W-1:0] deq_reg_addr_t_head              ;
  wire [`IMM_W     -1:0] deq_immediate_head               ;
  wire [`DISP_W    -1:0] deq_displacement_head            ;
  wire [`BIT_MODE_W-1:0] deq_bit_mode_head                ;
  wire [`ADDR_W    -1:0] deq_pc_head                      ;
  wire [`MICRO_W   -1:0] de_opcode                        ;
  wire [`REG_ADDR_W-1:0] de_reg_addr_d                    ;
  wire [`REG_ADDR_W-1:0] de_reg_addr_s                    ;
  wire [`REG_ADDR_W-1:0] de_reg_addr_t                    ;
  wire [`REG_W     -1:0] de_d                             ;
  wire [`REG_W     -1:0] de_s                             ;
  wire [`REG_W     -1:0] de_t                             ;
  wire [`IMM_W     -1:0] de_immediate                     ;
  wire [`DISP_W    -1:0] de_displacement                  ;
  wire [`BIT_MODE_W-1:0] de_bit_mode                      ;
  wire [`ADDR_W    -1:0] de_pc                            ;
  wire                   forward_to_d_from_exe            ;
  wire                   forward_to_s_from_exe            ;
  wire                   forward_to_t_from_exe            ;
  wire [EW_LAYER     :0] forward_to_d_from_wri            ;
  wire [EW_LAYER     :0] forward_to_s_from_wri            ;
  wire [EW_LAYER     :0] forward_to_t_from_wri            ;
  wire [`REG_W     -1:0] exe_d                            ;
  wire [`ADDR_W    -1:0] exe_bd                           ;
  wire                   exe_be                           ;
  wire                   exe_eflags_update                ;
  wire [`REG_W     -1:0] exe_eflags                       ;
  wire [`OPCODE_W  -1:0] ew_opcode                        ;
  wire [`REG_ADDR_W-1:0] ew_reg_addr_d                    ;
  wire [`REG_W     -1:0] ew_d                             ;
  wire [            2:0] ew_ld_offset                     ;
  wire [`OPCODE_W  -1:0] ew_layer_opcode    [EW_LAYER-1:0];
  wire [`REG_ADDR_W-1:0] ew_layer_reg_addr_d[EW_LAYER-1:0];
  wire [`REG_W     -1:0] ew_layer_d         [EW_LAYER-1:0];
  wire [`REG_W     -1:0] gpr                [`REG_N  -1:0];
  wire [`ADDR_W    -1:0] pc_to_fet                        ;
  wire                   flush                            ;
  wire [`OPCODE_W  -1:0] wri_opcode    [EW_LAYER:0]       ;
  wire [`REG_ADDR_W-1:0] wri_reg_addr_d[EW_LAYER:0]       ;
  wire [`REG_W     -1:0] wri_d         [EW_LAYER:0]       ;
  assign wri_opcode             [0] = ew_opcode           ;
  assign wri_reg_addr_d         [0] = ew_reg_addr_d       ;
  assign wri_d                  [0] = ew_d                ;
  assign wri_opcode    [EW_LAYER:1] = ew_layer_opcode     ;
  assign wri_reg_addr_d[EW_LAYER:1] = ew_layer_reg_addr_d ;
  assign wri_d         [EW_LAYER:1] = ew_layer_d          ;
  wire stall_phase                                        ;
  wire stall_pc                                           ;

  fetch_phase fetch_phase_1 (
    .inst             (inst             ),
    .pc_of_this_inst  (pc_to_fet        ),
    .mic_opcode       (fet_opcode       ),
    .mic_reg_addr_d   (fet_reg_addr_d   ),
    .mic_reg_addr_s   (fet_reg_addr_s   ),
    .mic_reg_addr_t   (fet_reg_addr_t   ),
    .mic_immediate    (fet_immediate    ),
    .mic_displacement (fet_displacement ),
    .mic_bit_mode     (fet_bit_mode     ),
    .mic_inst_valid   (fet_inst_valid   ),
    .mic_pc           (fet_pc           ),
    .stall            (stall_phase      ),
    .flush            (flush            ),
    .clk              (clk              ),
    .rstn             (rstn             )
  );

  decode_queue decode_queue_1 (
    .fet_opcode           (fet_opcode           ),
    .fet_reg_addr_d       (fet_reg_addr_d       ),
    .fet_reg_addr_s       (fet_reg_addr_s       ),
    .fet_reg_addr_t       (fet_reg_addr_t       ),
    .fet_immediate        (fet_immediate        ),
    .fet_displacement     (fet_displacement     ),
    .fet_bit_mode         (fet_bit_mode         ),
    .fet_inst_valid       (fet_inst_valid       ),
    .fet_pc               (fet_pc               ),
    .deq_opcode_head      (deq_opcode_head      ),
    .deq_reg_addr_d_head  (deq_reg_addr_d_head  ),
    .deq_reg_addr_s_head  (deq_reg_addr_s_head  ),
    .deq_reg_addr_t_head  (deq_reg_addr_t_head  ),
    .deq_immediate_head   (deq_immediate_head   ),
    .deq_displacement_head(deq_displacement_head),
    .deq_bit_mode_head    (deq_bit_mode_head    ),
    .deq_pc_head          (deq_pc_head          ),
    .stall                (stall_phase          ),
    .flush                (flush                ),
    .clk                  (clk                  ),
    .rstn                 (rstn                 )
  );
  

  decode_phase #(
    EW_LAYER
  ) decode_phase_1 (
    .deq_opcode_head      (deq_opcode_head      ),
    .deq_reg_addr_d_head  (deq_reg_addr_d_head  ),
    .deq_reg_addr_s_head  (deq_reg_addr_s_head  ),
    .deq_reg_addr_t_head  (deq_reg_addr_t_head  ),
    .deq_immediate_head   (deq_immediate_head   ),
    .deq_displacement_head(deq_displacement_head),
    .deq_bit_mode_head    (deq_bit_mode_head    ),
    .deq_pc_head          (deq_pc_head          ),
    .de_opcode            (de_opcode            ),
    .de_reg_addr_d        (de_reg_addr_d        ),
    .de_reg_addr_s        (de_reg_addr_s        ),
    .de_reg_addr_t        (de_reg_addr_t        ),
    .de_d                 (de_d                 ),
    .de_s                 (de_s                 ),
    .de_t                 (de_t                 ),
    .de_immediate         (de_immediate         ),
    .de_displacement      (de_displacement      ),
    .de_bit_mode          (de_bit_mode          ),
    .de_pc                (de_pc                ),
    .gpr                  (gpr                  ),
    .forward_to_d_from_exe(forward_to_d_from_exe),
    .forward_to_s_from_exe(forward_to_s_from_exe),
    .forward_to_t_from_exe(forward_to_t_from_exe),
    .forward_to_d_from_wri(forward_to_d_from_wri),
    .forward_to_s_from_wri(forward_to_s_from_wri),
    .forward_to_t_from_wri(forward_to_t_from_wri),
    .exe_d                (exe_d                ),
    .wri_d                (wri_d                ),
    .stall                (stall_phase          ),
    .flush                (flush                ),
    .clk                  (clk                  ),
    .rstn                 (rstn                 )
  );

  execute_phase execute_phase_1 (
    .de_opcode        (de_opcode        ),
    .de_reg_addr_d    (de_reg_addr_d    ),
    .de_d             (de_d             ),
    .de_s             (de_s             ),
    .de_t             (de_t             ),
    .de_immediate     (de_immediate     ),
    .de_displacement  (de_displacement  ),
    .de_bit_mode      (de_bit_mode      ),
    .de_pc            (de_pc            ),
    .gpr              (gpr              ),
    .exe_d            (exe_d            ),
    .exe_bd           (exe_bd           ),
    .exe_be           (exe_be           ),
    .exe_eflags_update(exe_eflags_update),
    .exe_eflags       (exe_eflags       ),
    .ew_opcode        (ew_opcode        ),
    .ew_reg_addr_d    (ew_reg_addr_d    ),
    .ew_d             (ew_d             ),
    .mem_addr         (mem_addr         ),
    .ew_ld_offset     (ew_ld_offset     ),
    .st_data          (st_data          ),
    .we               (we               ),
    .clk              (clk              ),
    .rstn             (rstn             )
  );

  write_back_phase #(
    LOAD_LATEMCY,
    EW_LAYER
  ) write_back_phase_1 (
    .de_opcode          (de_opcode          ),
    .exe_bd             (exe_bd             ),
    .exe_be             (exe_be             ),
    .exe_eflags         (exe_eflags         ),
    .ew_opcode          (ew_opcode          ),
    .ew_reg_addr_d      (ew_reg_addr_d      ),
    .ew_d               (ew_d               ),
    .ew_layer_opcode    (ew_layer_opcode    ),
    .ew_layer_reg_addr_d(ew_layer_reg_addr_d),
    .ew_layer_d         (ew_layer_d         ),
    .gpr                (gpr                ),
    .pc_to_mem          (pc_to_mem          ),
    .pc_to_fet          (pc_to_fet          ),
    .stall_pc           (stall_pc           ),
    .flush              (flush              ),
    .clk                (clk                ),
    .rstn               (rstn               )
  );

  forward_control #(
    EW_LAYER
  ) forward_control_1 (
    .dec_opcode           (deq_opcode_head      ),
    .dec_rd_addr          (deq_reg_addr_d_head  ),
    .dec_rs_addr          (deq_reg_addr_s_head  ),
    .dec_rt_addr          (deq_reg_addr_t_head  ),
    .exe_opcode           (de_opcode            ),
    .exe_rd_addr          (de_reg_addr_d        ),
    .wri_opcode           (wri_opcode           ),
    .wri_rd_addr          (wri_reg_addr_d       ),
    .forward_to_d_from_exe(forward_to_d_from_exe),
    .forward_to_s_from_exe(forward_to_s_from_exe),
    .forward_to_t_from_exe(forward_to_t_from_exe),
    .forward_to_d_from_wri(forward_to_d_from_wri),
    .forward_to_s_from_wri(forward_to_s_from_wri),
    .forward_to_t_from_wri(forward_to_t_from_wri)
  );

  stall_control #(
    LOAD_LATEMCY,
    EW_LAYER
  ) stall_control_1 (
    .dec_opcode      (deq_opcode_head                                                  ),
    .exe_opcode      (de_opcode                                                        ),
    .wri_opcode      (wri_opcode                                                       ),
    .forward_from_exe(forward_to_d_from_exe|forward_to_s_from_exe|forward_to_t_from_exe),
    .forward_from_wri(forward_to_d_from_wri|forward_to_s_from_wri|forward_to_t_from_wri),
    .stall_phase     (stall_phase                                                      ),
    .stall_pc        (stall_pc                                                         ),
    .clk             (clk                                                              ),
    .rstn            (rstn                                                             )
  );
endmodule

`default_nettype wire
