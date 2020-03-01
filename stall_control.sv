`default_nettype none
`include "common_params.h"

module stall_control #(
  parameter LOAD_LATENCY    = 1,
  parameter EW_LAYER        = 1
) (
  input wire [`OPCODE_W  -1:0] dec_opcode             ,
  input wire [`OPCODE_W  -1:0] exe_opcode             ,
  input wire [`OPCODE_W  -1:0] wri_opcode [EW_LAYER:0],
  input wire                   forward_from_exe       ,
  input wire [LOAD_LATENCY :0] forward_from_wri       ,
  output reg                   stall_phase            ,
  output reg                   stall_pc               ,
  input wire                   clk                    ,
  input wire                   rstn
);
  localparam LL = LOAD_LATENCY;
  localparam EW = EW_LAYER;

  wire           load_in_exe; // Execute Phase にLoad系命令(*1)があるか.
  wire [LL  :0]  load_in_wri; // Write Back Phase[0-LL] にLoad系命令があるか.
  
  load_inst_detector load_inst_detector_1(exe_opcode, load_in_exe);

  genvar i;
  generate
  for(i=0;i<LL+1;i=i+1) begin: gen_load
    load_inst_detector lid2(wri_opcode[i],load_in_wri[i]);
  end
  endgenerate

  wire stall_due_to_load =
    (  load_in_exe      &forward_from_exe       ) |
    (|(load_in_wri[LL:0]&forward_from_wri[LL:0])) ;

  assign stall_pc = stall_due_to_load;

  echo_assertion #(
    LOAD_LATENCY, 1
  ) echo_assertion_stall (
    .trigger  (stall_due_to_load),
    .assertion(stall_phase),
    .clk      (clk),
    .rstn     (rstn)
  );
endmodule

`default_nettype wire
