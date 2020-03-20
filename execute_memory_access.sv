`include "common_params.h"
`include "common_params_svfiles.h"

module transform_virt_phys #(
  parameter LOAD_LATENCY    = 1,
  parameter POST_DEC_LD     = 4,
  parameter IO_FILE_POINTER = 32'hfffff000
) (
  input  addr_t       virt_mem_addr,
  input  logic        virt_we      ,
  input   bmd_t       virt_bmd     ,
  input   reg_t       virt_st_data ,
  input   reg_t       phys_ld_data ,
  output addr_t       phys_mem_addr,
  output logic [ 7:0] phys_we      ,
  output  reg_t       phys_st_data ,
  output  reg_t       virt_ld_data ,
  output logic [31:0] out_data     ,
  output logic        out_req      ,
  input  logic        clk          ,
  input  logic        rstn         //
);
  integer i;

  reg [2:0] position [POST_DEC_LD-1:0];

  always @(posedge clk) begin
    if (~rstn) begin
      phys_we <= 0;
      out_req <= 0;
    end else if (virt_mem_addr==IO_FILE_POINTER) begin
      phys_we <= 0;
      out_req <= 0;
      if (virt_we) begin // OUT
        out_data <= virt_st_data[31:0];
        out_req  <= 1;
      end else begin     // IN
      end
    end else begin
    end
  end
endmodule

module execute_memory_access #(
  parameter IO_FILE_POINTER = 32'hfffff000
) (
  input miinst_t miinst   ,
  input    reg_t d        ,
  input    reg_t s        ,
  input    reg_t t        ,
  output  addr_t mem_addr ,
  output   bmd_t mem_bmd  ,
  output   reg_t st_data  ,
  output   logic we       
);
  assign st_data = d;
  assign we      =(miinst.op==MIOP_L)|(miinst.op==MIOP_OUT);
  assign mem_bmd = miinst.bmd;

  always_comb begin
    case (miinst.op)
      MIOP_IN :mem_addr <= IO_FILE_POINTER;
      MIOP_OUT:mem_addr <= IO_FILE_POINTER;
      default :mem_addr <= addr_t'(signed'({1'b0,s})+signed'(miinst.imm));
    endcase
  end
endmodule
