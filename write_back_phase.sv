`default_nettype none
`include "common_params.h"
`include "common_params_svfiles.h"

module write_back_phase #(
  parameter LOAD_LATENCY =    1,
  parameter INIT_RIP     =    0,
  parameter INIT_RSP     = 1024
) (
  input  ew_reg_t ew_reg         ,
  input  ew_sig_t ew_sig         ,
  output    reg_t gpr[`REG_N-1:0],
  output   addr_t pc_to_mem      ,
  output   addr_t pc_to_fet      ,
  input     logic stall_pc       ,
  output    logic flush          ,
  input     logic clk            ,
  input     logic rstn           //
);
  integer i;
  assign pc_to_mem = gpr[RIP];
  rut_t ew_rut;

  always @(posedge clk) begin
    if (~rstn) begin
      for (i=0;i<`REG_N;i=i+1) begin
        gpr[i] <= 0;
      end
      gpr[RIP] <= addr_t'(signed'(INIT_RIP))-`ADDR_W'(signed'(LOAD_LATENCY));
      gpr[RBP] <= addr_t'(INIT_RSP);
      gpr[RSP] <= addr_t'(INIT_RSP);
    end else begin
      if (ew_rut.to_gd) begin
        gpr[ew_reg.miinst.d] <= ew_reg.d;
      end

      if (ew_sig.eflags_update) begin
        gpr[EFL] <= ew_sig.eflags;
      end

      gpr[RIP] <= ew_sig.be? ew_sig.bd :
                        stall_pc ? pc_to_fet : gpr[RIP]+1 ;
    end
  end

  register_usage_table register_usage_table_1 (
    .miinst   (ew_reg.miinst),
    .rut      (ew_rut       )
  );

  pc_queue      #(LOAD_LATENCY) pc_queue_inst (.*);
  flush_control #(LOAD_LATENCY) flush_control_inst (
    .trigger(ew_sig.be),
    .flush  (flush    ),
    .clk    (clk      ),
    .rstn   (rstn     )
  );
endmodule

module pc_queue #(
  parameter LOAD_LATENCY = 1
) (
  input   reg_t pc_to_mem,
  output addr_t pc_to_fet,
  input   logic stall_pc ,
  input   logic clk      ,
  input   logic rstn     //
);
  integer i;

  reg_t pcq[LOAD_LATENCY-1:0];

  assign pc_to_fet = pcq[LOAD_LATENCY-1];
  
  always @(posedge clk) begin
    if (~rstn) begin
      for (i=0;i<LOAD_LATENCY;i=i+1) pcq[i] <= 0;
    end else if (~stall_pc) begin
      pcq[0] <= pc_to_mem;
      for (i=1;i<LOAD_LATENCY;i=i+1) pcq[i] <= pcq[i-1];
    end
  end
  
endmodule

module flush_control #(
  LOAD_LATENCY = 1
) (
  input  logic trigger,
  output logic flush  ,
  input  logic clk    ,
  input  logic rstn   //
);
  echo_assertion #(
    LOAD_LATENCY, 1
  ) echo_assertion_1 (
    .trigger  (trigger),
    .assertion(flush  ),
    .clk      (clk    ),
    .rstn     (rstn   )
  );
endmodule
`default_nettype wire
