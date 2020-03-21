`include "common_params.h"
`include "common_params_svfiles.h"

module transform_virt_phys #(
  parameter LOAD_LATENCY    = 1,
  parameter POST_DEC_LD     = 4,
  parameter IO_FILE_POINTER = 32'hfffff000
) (
  input  logic        virt_we      ,
  input  addr_t       virt_mem_addr,
  input   bmd_t       virt_mem_bmd ,
  input   reg_t       virt_st_data ,
  input   reg_t       phys_ld_data ,
  output addr_t       phys_mem_addr,
  output logic [ 7:0] phys_we      ,
  output  reg_t       phys_st_data ,
  output  reg_t       virt_ld_data ,
  input  logic [31:0] in_data      ,
  output logic        in_req       ,
  output logic [31:0] out_data     ,
  output logic        out_req      ,
  input  logic        clk          ,
  input  logic        rstn         //
);
  
  wire [2:0] position     = virt_mem_addr[2:0];
  reg  [2:0] position_queue [POST_DEC_LD-1:0];
  reg        io_req_queue   [POST_DEC_LD-1:0];
  wire [7:0] pre_phys_we  =
    (~virt_we             ) ? 8'h00:
    ( virt_mem_bmd==BMD_08) ? 8'h01:
    ( virt_mem_bmd==BMD_32) ? 8'h0f:
   /* virt_mem_bmd==BMD_64 */ 8'hff;

  /****************************
  * Mainly About Store & Out.
  *
  */
  always @(posedge clk) begin
    if (~rstn) begin
      phys_we <= 0;
      out_req <= 0;
    end else begin
      phys_we <= 0;
      out_req <= 0;
      case (virt_mem_addr)
        IO_FILE_POINTER:
        begin
          out_data <= virt_st_data[31:0];
          out_req  <= virt_we;
        end
        default:
        begin
          phys_mem_addr <= addr_t'({3'b000,virt_mem_addr[`ADDR_W-1:3]});
          phys_st_data  <=  reg_t'(virt_st_data << {position,3'b000});
          phys_we       <= pre_phys_we << position;
        end
      endcase
    end
  end

  /****************************
  * About Load Data.
  *
  */
  integer i;
  localparam LL = LOAD_LATENCY;
  
  assign virt_ld_data =
    (io_req_queue  [LL]      ) ? reg_t'(in_data                  ):
    (position_queue[LL]==3'd0) ? reg_t'(phys_ld_data[`REG_W-1: 0]):
    (position_queue[LL]==3'd1) ? reg_t'(phys_ld_data[`REG_W-1: 8]):
    (position_queue[LL]==3'd2) ? reg_t'(phys_ld_data[`REG_W-1:16]):
    (position_queue[LL]==3'd3) ? reg_t'(phys_ld_data[`REG_W-1:24]):
    (position_queue[LL]==3'd4) ? reg_t'(phys_ld_data[`REG_W-1:32]):
    (position_queue[LL]==3'd5) ? reg_t'(phys_ld_data[`REG_W-1:40]):
    (position_queue[LL]==3'd6) ? reg_t'(phys_ld_data[`REG_W-1:48]):
                                 reg_t'(phys_ld_data[`REG_W-1:56]);

  always @(posedge clk) begin
    if (~rstn) begin
      for(i=0;i<POST_DEC_LD;i=i+1) begin
        position_queue[i] <= 0;
        io_req_queue  [i] <= 0;
      end
    end else begin
      position_queue[0] <= position;
      io_req_queue  [0] <=(virt_mem_addr==IO_FILE_POINTER);

      for(i=1;i<POST_DEC_LD;i=i+1) begin
        position_queue[i] <= position_queue[i-1];
        io_req_queue  [i] <= io_req_queue  [i-1];
      end
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
  assign we      =(miinst.op==MIOP_S)|(miinst.op==MIOP_OUT);
  assign mem_bmd = miinst.bmd;

  always_comb begin
    case (miinst.op)
      MIOP_IN :mem_addr <= IO_FILE_POINTER;
      MIOP_OUT:mem_addr <= IO_FILE_POINTER;
      default :mem_addr <= addr_t'(signed'({1'b0,s})+signed'(miinst.imm));
    endcase
  end
endmodule
