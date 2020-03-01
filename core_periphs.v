`default_nettype none
`include "common_params.h"

module core_periphs #(
  parameter LOAD_LATEMCY = 1
) (
  input  wire [`DATA_W  -1:0] ld_data_for_inst,
  input  wire [`DATA_W  -1:0] ld_data         ,
  output wire [`DATA_W  -1:0] st_data         ,
  output wire [`ADDR_W  -1:0] mem_addr        ,
  output wire [`ADDR_W  -1:0] pc_to_mem       ,
  output wire [`DATA_W/8-1:0] we              ,
  input  wire                 clk             ,
  input  wire                 rstn            //
);
  core #(
    LOAD_LATEMCY
  ) core_1 (
    .ld_data_for_inst(ld_data_for_inst),
    .ld_data         (ld_data         ),
    .st_data         (st_data         ),
    .mem_addr        (mem_addr        ),
    .pc_to_mem       (pc_to_mem       ),
    .we              (we              ),
    .clk             (clk             ),
    .rstn            (rstn            )
  );

endmodule
  
`default_nettype wire
