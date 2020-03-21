`include "common_params.h"
`include "common_params_svfiles.h"

module core #(
  parameter LOAD_LATEMCY    = 1,
  parameter INIT_RIP        = 0,
  parameter INIT_RSP        = 1024,
  parameter IO_FILE_POINTER = 32'hfffff000
) (
  input   reg_t        ld_data_for_inst,
  input   reg_t        ld_data         ,
  output  reg_t        st_data         ,
  output addr_t        mem_addr        ,
  output  logic [ 7:0] we              ,
  output addr_t        pc_to_mem       ,
  output  logic [31:0] out_data        ,
  output  logic        out_req         ,
  input   logic        out_busy        ,
  input wire           clk             ,
  input wire           rstn            //
);
  localparam POST_DEC_LD = LOAD_LATEMCY+3;

  miinst_t fet_miinst [`MQ_N-1:0]       ;
  logic    fet_valid                    ;
  miinst_t deq_miinst_head              ;
  de_reg_t de_reg                       ;
  ew_sig_t ew_sig                       ;
  ew_reg_t ew_reg                       ;
  miinst_t pos_miinst[POST_DEC_LD-1:0]  ;
  reg_t    pos_d     [POST_DEC_LD-1:0]  ;
  reg_t    gpr       [`REG_N     -1:0]  ;
  addr_t   pc_to_fet                    ;
  fwd_t    fwd_sig_from[POST_DEC_LD-1:0];
  reg_t    fwd_val_from[POST_DEC_LD-1:0];
  logic    stall_phase                  ;
  logic    stall_pc                     ;
  logic    flush                        ;
  
  // 仮想アドレス的な
  reg_t    virt_st_data                 ;
  reg_t    virt_ld_data                 ;
  addr_t   virt_mem_addr                ;
  bmd_t    virt_mem_bmd                 ;
  logic    virt_we                      ;

  transform_virt_phys #(
    LOAD_LATEMCY,
    POST_DEC_LD,
    IO_FILE_POINTER
  ) transform_virt_phys_inst (
    .virt_we      (virt_we      ),
    .virt_mem_addr(virt_mem_addr),
    .virt_mem_bmd (virt_mem_bmd ),
    .virt_st_data (virt_st_data ),
    .phys_ld_data (ld_data      ),
    .phys_mem_addr(mem_addr     ),
    .phys_we      (we           ),
    .phys_st_data (st_data      ),
    .virt_ld_data (virt_ld_data ),
    .out_data     (out_data     ),
    .out_req      (out_req      ),
    .clk          (clk          ),
    .rstn         (rstn         )
  );
  
  assign pc_to_mem = gpr[RIP][31:3];
  inst_t inst;
  assign inst =
    (pc_to_fet[2:0]==3'b111) ? ld_data_for_inst[ 7: 0]:
    (pc_to_fet[2:0]==3'b110) ? ld_data_for_inst[15: 8]:
    (pc_to_fet[2:0]==3'b101) ? ld_data_for_inst[23:16]:
    (pc_to_fet[2:0]==3'b100) ? ld_data_for_inst[31:24]:
    (pc_to_fet[2:0]==3'b011) ? ld_data_for_inst[39:32]:
    (pc_to_fet[2:0]==3'b010) ? ld_data_for_inst[47:40]:
    (pc_to_fet[2:0]==3'b001) ? ld_data_for_inst[55:48]:
                               ld_data_for_inst[63:56];

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
    POST_DEC_LD
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
    .de_reg    (de_reg       ),
    .gpr       (gpr          ),
    .ew_sig    (ew_sig       ),
    .ew_reg    (ew_reg       ),
    .pos_miinst(pos_miinst   ),
    .pos_d     (pos_d        ),
    .st_data   (virt_st_data ),
    .ld_data   (virt_ld_data ),
    .mem_addr  (virt_mem_addr),
    .mem_bmd   (virt_mem_bmd ),
    .we        (virt_we      ),
    .clk       (clk          ),
    .rstn      (rstn         )
  );

  write_back_phase #(
    LOAD_LATEMCY
  ) write_back_phase_1 (
    .ew_reg   (ew_reg   ),
    .ew_sig   (ew_sig   ),
    .gpr      (gpr      ),
    .pc_to_fet(pc_to_fet),
    .stall_pc (stall_pc ),
    .flush    (flush    ),
    .clk      (clk      ),
    .rstn     (rstn     )
  );

  stall_control #(
    LOAD_LATEMCY,
    POST_DEC_LD
  ) stall_control_1 (
    .dec_miinst   (deq_miinst_head),
    .pos_miinst   (pos_miinst     ),
    .pos_d        (pos_d          ),
    .fwd_sig_from (fwd_sig_from   ),
    .fwd_val_from (fwd_val_from   ),
    .stall_phase  (stall_phase    ),
    .stall_pc     (stall_pc       ),
    .out_busy     (out_busy       ),
    .clk          (clk            ),
    .rstn         (rstn           )
  );
  
  name_t name [POST_DEC_LD-1+1:0];

  genvar i;
  instruction_name_by_ascii inba_dec (
    .miinst(deq_miinst_head),
    .name(name[0])
  );
  generate
  begin
    for(i=0;i<POST_DEC_LD;i=i+1) begin : debug_no_tameni
      instruction_name_by_ascii inba_pos (
        .miinst(pos_miinst[i]),
        .name(name[i+1])
      );
    end
  end
  endgenerate
endmodule
