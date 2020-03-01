`default_nettype none
`include "common_params.h"

module write_back_phase #(
  parameter LOAD_LATENCY = 1,
  parameter EW_LAYER     = 1
) (
  input wire [`OPCODE_W  -1:0] de_opcode                        ,
  input wire [`ADDR_W    -1:0] exe_bd                           ,
  input wire                   exe_be                           ,
  input wire [`REG_W     -1:0] exe_eflags                       ,
  input wire [`OPCODE_W  -1:0] ew_opcode                        ,
  input wire [`REG_ADDR_W-1:0] ew_reg_addr_d                    ,
  input wire [`REG_W     -1:0] ew_d                             ,
  input wire [            2:0] ew_ld_offset                     ,
  output reg [`OPCODE_W  -1:0] ew_layer_opcode    [EW_LAYER-1:0],
  output reg [`REG_ADDR_W-1:0] ew_layer_reg_addr_d[EW_LAYER-1:0],
  output reg [`REG_W     -1:0] ew_layer_d         [EW_LAYER-1:0],
  output reg [`REG_W     -1:0] gpr                [`REG_N  -1:0],
  output reg [`ADDR_W    -1:0] pc_to_mem                        , // メモリ行きのPC
  output reg [`ADDR_W    -1:0] pc_to_fet                        , // fetch phase行きのPC
  output reg [`DATA_W    -1:0] ld_data                          ,
  input wire                   stall_pc                         ,
  output reg                   flush                            ,
  input wire                   clk                              ,
  input wire                   rstn
);
  integer i;
  
  assign pc_to_mem = {3'b0,gpr[`RIP_ADDR][`ADDR_W-1:3]};
  assign pc_to_fet = pc_queue [LOAD_LATENCY-1];

  reg  [`ADDR_W-1:0] pc_queue [LOAD_LATENCY-1:0];
  wire [`REG_W -1:0] mask;
  
  reg  [2:0] ew_layer_ld_offset [EW_LAYER-1:0];

  wire [`REG_W-1:0] ld_data_to_write =
    (ew_layer_ld_offset[LOAD_LATENCY]==3'd0) ? `REG_W'(ld_data[`DATA_W-1: 0]):
    (ew_layer_ld_offset[LOAD_LATENCY]==3'd1) ? `REG_W'(ld_data[`DATA_W-1: 8]):
    (ew_layer_ld_offset[LOAD_LATENCY]==3'd2) ? `REG_W'(ld_data[`DATA_W-1:16]):
    (ew_layer_ld_offset[LOAD_LATENCY]==3'd3) ? `REG_W'(ld_data[`DATA_W-1:24]):
    (ew_layer_ld_offset[LOAD_LATENCY]==3'd4) ? `REG_W'(ld_data[`DATA_W-1:32]):
    (ew_layer_ld_offset[LOAD_LATENCY]==3'd5) ? `REG_W'(ld_data[`DATA_W-1:40]):
    (ew_layer_ld_offset[LOAD_LATENCY]==3'd6) ? `REG_W'(ld_data[`DATA_W-1:48]):
                                               `REG_W'(ld_data[`DATA_W-1:56]);

  always @(posedge clk) begin
    ew_layer_opcode     [0] <= ~rstn ? 0 : ew_opcode    ;
    ew_layer_reg_addr_d [0] <= ~rstn ? 0 : ew_reg_addr_d;
    ew_layer_d          [0] <= ~rstn ? 0 : ew_d         ;
    ew_layer_ld_offset  [0] <= ~rstn ? 0 : ew_ld_offset ;

    for (i=1;i<EW_LAYER;i=i+1) begin
      if (i==LOAD_LATENCY) begin
        ew_layer_d [i] <= ~rstn ? 0 :
          (ew_layer_opcode[i-1]==`MICRO_LB) ? `REG_W'(ld_data_to_write[ 7:0]):
          (ew_layer_opcode[i-1]==`MICRO_LD) ? `REG_W'(ld_data_to_write[32:0]):
          (ew_layer_opcode[i-1]==`MICRO_LQ) ? `REG_W'(ld_data_to_write[63:0]):
                                                       ew_layer_d [i-1] ;
      end else begin
        ew_layer_d [i] <= ~rstn ? 0 : ew_layer_d [i-1];
      end
      ew_layer_opcode     [i] <= ~rstn ? 0 : ew_layer_opcode    [i-1];
      ew_layer_reg_addr_d [i] <= ~rstn ? 0 : ew_layer_reg_addr_d[i-1];
      ew_layer_ld_offset  [i] <= ~rstn ? 0 : ew_layer_ld_offset [i-1];
    end
  end

  wire d_to_gpr;


  always @(posedge clk) begin
    if (~rstn) begin
      for (i=0;i<`REG_N;i=i+1) begin
        if (i==`RIP_ADDR) begin
          gpr[i] <= signed'(-1);
        end else if (i==`RSP_ADDR) begin
          gpr[i] <= signed'(-2);
        end else begin
          gpr[i] <= 0;
        end
      end
    end else begin
      if (d_to_gpr) begin
        gpr[ew_layer_reg_addr_d[EW_LAYER-1]] <= ew_layer_d[EW_LAYER-1];
      end
      gpr[`RIP_ADDR] <= exe_be    ? exe_bd    :
                        stall_pc  ? pc_to_fet : gpr[`RIP_ADDR]+1 ;

      gpr[`EFL_ADDR] <= exe_eflags|(mask&gpr[`EFL_ADDR]);
    end
  end

  always @(posedge clk) begin
    pc_queue   [0] <= ~rstn ? 0 : stall_pc ? pc_queue[0] : gpr[`RIP_ADDR];

    for (i=1;i<LOAD_LATENCY;i=i+1) begin
      pc_queue [i] <= ~rstn ? 0 : stall_pc ? pc_queue[i] : pc_queue[i-1]; 
    end
  end

  register_usage_table register_usage_table_1 (
    .opcode   (ew_layer_opcode[EW_LAYER-1]),
    .d_to_gpr (d_to_gpr)
  );
  
  eflags_mask eflags_mask_1 (
    .opcode (de_opcode),
    .mask   (mask)
  );

  echo_assertion #(
    LOAD_LATENCY, 1
  ) echo_assertion_1 (
    .trigger  (exe_be),
    .assertion(flush),
    .clk      (clk),
    .rstn     (rstn)
  );
endmodule

module eflags_mask (
  input wire [`OPCODE_W-1:0] opcode,
  output reg [`REG_W   -1:0] mask
);
  assign mask =
    (opcode==`MICRO_CMP ) ? ~(`EFLAGS_CF|`EFLAGS_OF|`EFLAGS_PF|`EFLAGS_ZF|`EFLAGS_SF) :
    (opcode==`MICRO_CMPI) ? ~(`EFLAGS_CF|`EFLAGS_OF|`EFLAGS_PF|`EFLAGS_ZF|`EFLAGS_SF) : signed'(-1);
endmodule
`default_nettype wire
