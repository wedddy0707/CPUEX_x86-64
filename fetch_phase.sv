`default_nettype none
`include "common_params.h"
`include "common_params_svfiles.sv"


module fetch_phase #(
  parameter LOAD_LATENCY = 1
) (
  input  inst_t   inst             ,
  input  addr_t   pc               ,
  output miinst_t miinst[`MQ_N-1:0],
  output reg      valid            ,
  input wire      stall            ,
  input wire      flush            ,
  input wire      clk              ,
  input wire      rstn
);
  // ステートとそのサポート役のレジスタたち
  // (これらの直積をステートと言った方が正確かもしれない)
  fstate        state          ;
  reg   [ 3:0]  rex            ;
  const_info_t  imm            ;
  const_info_t  disp           ;
  
  // 些末な問題を解決するためのレジスタやワイヤ線
  reg ignore_meaningless_add;
  wire head_inst = valid|(ignore_meaningless_add&inst!=8'b0);
  
  integer i;

  always @(posedge clk) begin
    if (~rstn) begin
      ignore_meaningless_add  <=        1;
      state.obj               <= OPCODE_1;
      rex                     <=        0;
      valid                   <=        0;
    end else if (flush) begin
      rex       <=        0;
      valid     <=        0;
      state.obj <= OPCODE_1;
    end else if (stall) begin
      // stall中は
      // 何もしNOTHING
    end else if (~ignore_meaningless_add || inst!=8'b0) begin
      ignore_meaningless_add <= 0;
      valid                  <= 0;

      if (head_inst) begin
        rex <= 0;
      end

      case (state.obj)
        OPCODE_1:
        begin
          state   <=  state_opcode_1;
          miinst  <= miinst_opcode_1;
          name    <=   name_opcode_1;
          imm     <=    imm_opcode_1;
          disp    <=   disp_opcode_1;
          rex     <=    rex_opcode_1;
          valid   <=  valid_opcode_1;
        end
        OPCODE_2:
        begin
          state   <=  state_opcode_2;
          miinst  <= miinst_opcode_2;
          name    <=   name_opcode_2;
          imm     <=    imm_opcode_2;
          disp    <=   disp_opcode_2;
          rex     <=    rex_opcode_2;
          valid   <=  valid_opcode_2;
        end
        MODRM:
        begin
          state   <=  state_modrm;
          miinst  <= miinst_modrm;
          name    <=   name_modrm;
          imm     <=    imm_modrm;
          disp    <=   disp_modrm;
          rex     <=    rex_modrm;
          valid   <=  valid_modrm;
        end
        SIB:
        begin
          state   <=  state_sib;
          miinst  <= miinst_sib;
          name    <=   name_sib;
          imm     <=    imm_sib;
          disp    <=   disp_sib;
          rex     <=    rex_sib;
          valid   <=  valid_sib;
        end
        DISPLACEMENT:
        begin
          state   <=  state_displacement;
          miinst  <= miinst_displacement;
          name    <=   name_displacement;
          imm     <=    imm_displacement;
          disp    <=   disp_displacement;
          rex     <=    rex_displacement;
          valid   <=  valid_displacement;
        end
        IMMEDIATE:
        begin
          state   <=  state_immediate;
          miinst  <= miinst_immediate;
          name    <=   name_immediate;
          imm     <=    imm_immediate;
          disp    <=   disp_immediate;
          rex     <=    rex_immediate;
          valid   <=  valid_immediate;
        end
        default:
        begin
          state <= S_OPCODE_1;
        end
      endcase
      
      for (i=0;i<`MQ_N;i=i+1) begin
        miinst[i].pc <= pc;
      end
    end
  end

  fstate        state_opcode_1               ;
  miinst_t     miinst_opcode_1    [`MQ_N-1:0];
  name_t         name_opcode_1               ;
  const_info_t    imm_opcode_1               ;
  const_info_t   disp_opcode_1               ;
  logic [ 3:0]    rex_opcode_1               ;
  logic         valid_opcode_1               ;
  fstate        state_opcode_2               ;
  miinst_t     miinst_opcode_2    [`MQ_N-1:0];
  name_t         name_opcode_2               ;
  const_info_t    imm_opcode_2               ;
  const_info_t   disp_opcode_2               ;
  logic [ 3:0]    rex_opcode_2               ;
  logic         valid_opcode_2               ;
  fstate        state_modrm                  ;
  miinst_t     miinst_modrm       [`MQ_N-1:0];
  name_t         name_modrm                  ;
  const_info_t    imm_modrm                  ;
  const_info_t   disp_modrm                  ;
  logic [ 3:0]    rex_modrm                  ;
  logic         valid_modrm                  ;
  fstate        state_sib                    ;
  miinst_t     miinst_sib         [`MQ_N-1:0];
  name_t         name_sib                    ;
  const_info_t    imm_sib                    ;
  const_info_t   disp_sib                    ;
  logic [ 3:0]    rex_sib                    ;
  logic         valid_sib                    ;
  fstate        state_displacement           ;
  miinst_t     miinst_displacement[`MQ_N-1:0];
  name_t         name_displacement           ;
  const_info_t    imm_displacement           ;
  const_info_t   disp_displacement           ;
  logic [ 3:0]    rex_displacement           ;
  logic         valid_displacement           ;
  fstate        state_immediate              ;
  miinst_t     miinst_immediate   [`MQ_N-1:0];
  name_t         name_immediate              ;
  const_info_t    imm_immediate              ;
  const_info_t   disp_immediate              ;
  logic [ 3:0]    rex_immediate              ;
  logic         valid_immediate              ;

  fetch_phase_opcode_1 fetch_phase_opcode_1_inst (
    .inst         (inst           ),
    .pc           (pc             ),
    .state_as_src (state          ),
    .state        (state_opcode_1 ),
    .miinst_as_src(miinst         ),
    .miinst       (miinst_opcode_1),
    .name_as_src  (name           ),
    .name         (name_opcode_1  ),
    .imm_as_src   (imm            ),
    .imm          (imm_opcode_1   ),
    .disp_as_src  (disp           ),
    .disp         (disp_opcode_1  ),
    .rex_as_src   (rex            ),
    .rex          (rex_opcode_1   ),
    .valid        (valid_opcode_1 )
  );
  fetch_phase_opcode_2 fetch_phase_opcode_2_inst (
    .inst         (inst           ),
    .pc           (pc             ),
    .state_as_src (state          ),
    .state        (state_opcode_2 ),
    .miinst_as_src(miinst         ),
    .miinst       (miinst_opcode_2),
    .name_as_src  (name           ),
    .name         (name_opcode_2  ),
    .imm_as_src   (imm            ),
    .imm          (imm_opcode_2   ),
    .disp_as_src  (disp           ),
    .disp         (disp_opcode_2  ),
    .rex_as_src   (rex            ),
    .rex          (rex_opcode_2   ),
    .valid        (valid_opcode_2 )
  );
  fetch_phase_modrm fetch_phase_modrm_inst (
    .inst         (inst        ),
    .pc           (pc          ),
    .state_as_src (state       ),
    .state        (state_modrm ),
    .miinst_as_src(miinst      ),
    .miinst       (miinst_modrm),
    .name_as_src  (name        ),
    .name         (name_modrm  ),
    .imm_as_src   (imm         ),
    .imm          (imm_modrm   ),
    .disp_as_src  (disp        ),
    .disp         (disp_modrm  ),
    .rex_as_src   (rex         ),
    .rex          (rex_modrm   ),
    .valid        (valid_modrm )
  );
  fetch_phase_sib fetch_phase_sib_inst (
    .inst         (inst      ),
    .pc           (pc        ),
    .state_as_src (state     ),
    .state        (state_sib ),
    .miinst_as_src(miinst    ),
    .miinst       (miinst_sib),
    .name_as_src  (name      ),
    .name         (name_sib  ),
    .imm_as_src   (imm       ),
    .imm          (imm_sib   ),
    .disp_as_src  (disp      ),
    .disp         (disp_sib  ),
    .rex_as_src   (rex       ),
    .rex          (rex_sib   ),
    .valid        (valid_sib )
  );
  fetch_phase_displacement fetch_phase_displacement_inst (
    .inst         (inst               ),
    .pc           (pc                 ),
    .state_as_src (state              ),
    .state        (state_displacement ),
    .miinst_as_src(miinst             ),
    .miinst       (miinst_displacement),
    .name_as_src  (name               ),
    .name         (name_displacement  ),
    .imm_as_src   (imm                ),
    .imm          (imm_displacement   ),
    .disp_as_src  (disp               ),
    .disp         (disp_displacement  ),
    .rex_as_src   (rex                ),
    .rex          (rex_displacement   ),
    .valid        (valid_displacement )
  );
  fetch_phase_immediate fetch_phase_immediate_inst (
    .inst         (inst             ),
    .pc           (pc               ),
    .state_as_src (state            ),
    .state        (state_immediate  ),
    .miinst_as_src(miinst           ),
    .miinst       (miinst_immediate ),
    .name_as_src  (name             ),
    .name         (name_immediate   ),
    .imm_as_src   (imm              ),
    .imm          (imm_immediate    ),
    .disp_as_src  (disp             ),
    .disp         (disp_immediate   ),
    .rex_as_src   (rex              ),
    .rex          (rex_immediate    ),
    .valid        (valid_immediate  )
  );
endmodule
`default_nettype wire
