`default_nettype none

module core_periphs #(
  parameter LOAD_LATEMCY    =    1,
  parameter ACTUAL_ADDR_W   =   13,
  parameter        ADDR_W   =   32,
  parameter DATA_W          =   64,
  parameter WE_W            =    8,
  parameter INIT_RIP        =    0,
  parameter INIT_RSP        = 1024,
  parameter IO_FILE_POINTER = 32'hfffff000
) (
  input  wire [DATA_W       -1:0] ld_data_for_inst ,
  input  wire [DATA_W       -1:0] ld_data          ,
  output wire [DATA_W       -1:0] st_data          ,
  output wire [ACTUAL_ADDR_W-1:0] mem_addr         ,
  output wire [ACTUAL_ADDR_W-1:0] pc_to_mem        ,
  output wire [WE_W         -1:0] we               ,
  output wire                     axi_awvalid      ,
  input  wire                     axi_awready      ,
  output wire [31:0]              axi_awaddr       ,
  output wire [ 2:0]              axi_awprot       ,
  output wire                     axi_wvalid       ,
  input  wire                     axi_wready       ,
  output wire [31:0]              axi_wdata        ,
  output wire [ 3:0]              axi_wstrb        ,
  input  wire                     axi_bvalid       ,
  output wire                     axi_bready       ,
  input  wire [ 1:0]              axi_bresp        ,
  output wire                     axi_arvalid      ,
  input  wire                     axi_arready      ,
  output wire [31:0]              axi_araddr       ,
  output wire [ 2:0]              axi_arprot       ,
  input  wire                     axi_rvalid       ,
  output wire                     axi_rready       ,
  input  wire [31:0]              axi_rdata        ,
  input  wire [ 1:0]              axi_rresp        ,
  input  wire                     clk              ,
  input  wire                     rstn             //
);
  wire [32    -1:0]  out_data;
  wire               out_req ;
  wire               out_busy;
  wire                in_busy;
  wire [ADDR_W-1:0] consumer_pointer = 0;
  wire [ADDR_W-1:0]  mem_addr_with_ideal_width;
  wire [ADDR_W-1:0] pc_to_mem_with_ideal_width;

  assign mem_addr  =  mem_addr_with_ideal_width[ACTUAL_ADDR_W-1:0];
  assign pc_to_mem = pc_to_mem_with_ideal_width[ACTUAL_ADDR_W-1:0];

  core #(
    LOAD_LATEMCY   ,
    INIT_RIP       ,
    INIT_RSP       ,
    IO_FILE_POINTER
  ) core_1 (
    .ld_data_for_inst(ld_data_for_inst          ),
    .ld_data         (ld_data                   ),
    .st_data         (st_data                   ),
    .mem_addr        (mem_addr_with_ideal_width ),
    .pc_to_mem       (pc_to_mem_with_ideal_width),
    .we              (we                        ),
    .out_req         (out_req                   ),
    .out_data        (out_data                  ),
    .out_busy        (out_busy                  ),
    .clk             (clk                       ),
    .rstn            (rstn                      )
  );

  io_controller io_controller_inst (
    .out_req         (out_req          ),
    .out_data        (out_data         ),
    .consumer_pointer(consumer_pointer ),
    .in_busy         (in_busy          ),
    .out_busy        (out_busy         ),
    .axi_awvalid     (axi_awvalid      ),
    .axi_awready     (axi_awready      ),
    .axi_awaddr      (axi_awaddr       ),
    .axi_awprot      (axi_awprot       ),
    .axi_wvalid      (axi_wvalid       ),
    .axi_wready      (axi_wready       ),
    .axi_wdata       (axi_wdata        ),
    .axi_wstrb       (axi_wstrb        ),
    .axi_bvalid      (axi_bvalid       ),
    .axi_bready      (axi_bready       ),
    .axi_bresp       (axi_bresp        ),
    .axi_arvalid     (axi_arvalid      ),
    .axi_arready     (axi_arready      ),
    .axi_araddr      (axi_araddr       ),
    .axi_arprot      (axi_arprot       ),
    .axi_rvalid      (axi_rvalid       ),
    .axi_rready      (axi_rready       ),
    .axi_rdata       (axi_rdata        ),
    .axi_rresp       (axi_rresp        ),
    .clk             (clk              ),
    .rstn            (rstn             )
  );
endmodule
  
`default_nettype wire
