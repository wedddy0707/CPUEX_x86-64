`default_nettype none

module core_periphs #(
  parameter LOAD_LATEMCY  =    1,
  parameter ACTUAL_ADDR_W =   13,
  parameter        ADDR_W =   32,
  parameter DATA_W        =   64,
  parameter WE_W          =    8,
  parameter INIT_RIP      =    0,
  parameter INIT_RSP      = 1024
) (
  input  wire [DATA_W       -1:0] ld_data_for_inst,
  input  wire [DATA_W       -1:0] ld_data         ,
  output wire [DATA_W       -1:0] st_data         ,
  output wire [ACTUAL_ADDR_W-1:0] mem_addr        ,
  output wire [ACTUAL_ADDR_W-1:0] pc_to_mem       ,
  output wire [WE_W         -1:0] we              ,
  input  wire                     clk             ,
  input  wire                     rstn            //
);
  wire [ADDR_W-1:0]  mem_addr_with_ideal_width;
  wire [ADDR_W-1:0] pc_to_mem_with_ideal_width;

  assign mem_addr  =  mem_addr_with_ideal_width[ACTUAL_ADDR_W-1:0];
  assign pc_to_mem = pc_to_mem_with_ideal_width[ACTUAL_ADDR_W-1:0];
  core #(
    LOAD_LATEMCY,
    INIT_RIP    ,
    INIT_RSP
  ) core_1 (
    .ld_data_for_inst(ld_data_for_inst          ),
    .ld_data         (ld_data                   ),
    .st_data         (st_data                   ),
    .mem_addr        (mem_addr_with_ideal_width ),
    .pc_to_mem       (pc_to_mem_with_ideal_width),
    .we              (we                        ),
    .clk             (clk                       ),
    .rstn            (rstn                      )
  );

endmodule
  
`default_nettype wire
