`default_nettype none
`include "common_params.h"

module io_controller #(
  parameter ACTUAL_ADDR_W= 32,
  parameter INIT_POINTER =  0,
  parameter HIGH_POINTER = 10,
  parameter DEBUG_IGNORE_IN_BUSY        = 1'b0,
  parameter DEBUG_IGNORE_CONTEST_SERVER = 1'b1
) (
  input wire                out_req,
  input wire [`WORD_W-1:0]  out_data,
  input wire [`ADDR_W-1:0]  consumer_pointer,
  output wire                in_busy,
  output wire               out_busy,
  
  output wire [`ADDR_W-1:0]  mem_addr,
  output wire [`WORD_W-1:0]  mem_data,
  output wire                mem_we,

  // I/O via AXI4
  // AXI4-lite master memory interface
  // address write channel
  output wire           axi_awvalid,
  input wire            axi_awready,
  output wire[31:0]     axi_awaddr,
  output wire[2:0]      axi_awprot,
  // data write channel
  output wire           axi_wvalid,
  input wire            axi_wready,
  output wire[31:0]     axi_wdata,
  output wire[3:0]      axi_wstrb,
  // response channel
  input wire            axi_bvalid,
  output wire           axi_bready,
  input wire [1:0]      axi_bresp,
  // address read channel
  output wire           axi_arvalid,
  input wire            axi_arready,
  output wire[31:0]     axi_araddr,
  output wire[2:0]      axi_arprot,
  // read data channel
  input wire            axi_rvalid,
  output wire           axi_rready,
  input wire [31:0]     axi_rdata,
  input wire [1:0]      axi_rresp,
  
  input wire clk,
  input wire rstn
);

  wire [31:0] stat_reg;      // ステータスレジスタの情報を保持
  wire        stat_reg_new;

  io_data_in #(
    INIT_POINTER,
    HIGH_POINTER,
    DEBUG_IGNORE_IN_BUSY
  ) io_data_in_1 (
    .axi_arvalid      (axi_arvalid),
    .axi_arready      (axi_arready),
    .axi_araddr       (axi_araddr),
    .axi_arprot       (axi_arprot),
    .axi_rvalid       (axi_rvalid),
    .axi_rready       (axi_rready),
    .axi_rdata        (axi_rdata),
    .axi_rresp        (axi_rresp),
    .consumer_pointer (consumer_pointer),
    .stat_reg         (stat_reg),
    .stat_reg_new     (stat_reg_new),
    .mem_addr         (mem_addr),
    .mem_data         (mem_data),
    .mem_we           (mem_we),
    .in_busy          (in_busy),
    .clk              (clk),
    .rstn             (rstn)
  );

  io_data_out #(
    DEBUG_IGNORE_CONTEST_SERVER
  ) io_data_out_1 (
    .axi_awvalid  (axi_awvalid),
    .axi_awready  (axi_awready),
    .axi_awaddr   (axi_awaddr),
    .axi_awprot   (axi_awprot),
    .axi_wvalid   (axi_wvalid),
    .axi_wready   (axi_wready),
    .axi_wdata    (axi_wdata),
    .axi_wstrb    (axi_wstrb),
    .axi_bvalid   (axi_bvalid),
    .axi_bready   (axi_bready),
    .axi_bresp    (axi_bresp),
    .stat_reg     (stat_reg),
    .stat_reg_new (stat_reg_new),
    .out_req      (out_req),
    .out_data     (out_data),
    .out_busy     (out_busy),
    .clk          (clk),
    .rstn         (rstn)
  );

endmodule

module io_data_out #(
  DEBUG_IGNORE_CONTEST_SERVER = 1'b1
) (
  output reg               axi_awvalid,
  input wire               axi_awready,
  output reg [31:0]        axi_awaddr,
  output reg [2:0]         axi_awprot,
  // data write channel
  output reg               axi_wvalid,
  input wire               axi_wready,
  output reg [31:0]        axi_wdata,
  output reg [3:0]         axi_wstrb,
  // response channel
  input wire               axi_bvalid,
  output reg               axi_bready,
  input wire [1:0]         axi_bresp,

  input wire [31:0]        stat_reg,
  input wire               stat_reg_new,

  input wire               out_req,
  input wire [`WORD_W-1:0] out_data,
  output wire              out_busy,

  input wire               clk,
  input wire               rstn
);
  enum {
    OUT_WAIT,
    OUT_DATA_A,
    OUT_DATA_B,
    OUT_DATA_C1,
    OUT_DATA_C2,
    OUT_DATA_D,

    OUT_WAIT_FOR_0XAA,
    OUT_DATA_A_FOR_0XAA
  } out_state;

  /*******************************************************
  * AXI UART Liteでは使わないワイヤ線
  * axi_awprot, axi_wstrb
  */
  assign axi_awprot = 0;
  assign axi_wstrb  = 0;

  /*******************************************************
  * TX FIFO Emptyを最後に確認してから何回OUTしたか数える
  * out_max   : OUTの回数の上限
  * out_count : 現在のカウント数
  * out_done  : OUTが1回完了した時のトリガ
  * out_busy  : coreが out_req を発行するのをinterrupt
  *
  */
  localparam  out_max   = 4'd15;
  reg  [ 3:0] out_count;
  wire        out_done  = (out_state==OUT_DATA_D&&axi_bvalid);
  assign      out_busy  =~(out_state==OUT_DATA_A&&~out_req&&out_count<out_max);

  always @(posedge clk) begin
    out_count <=
      (~rstn)                    ?    out_max   :
      (stat_reg[2]&stat_reg_new) ? 4'(out_done) :
      (out_count==out_max)       ?    out_max   : out_count+4'(out_done);
  end

  localparam tx_fifo_addr = 32'd4;

  always @(posedge clk) begin
    if (~rstn) begin
      out_state   <=(DEBUG_IGNORE_CONTEST_SERVER)? OUT_WAIT : OUT_WAIT_FOR_0XAA;
      axi_awvalid <= 0;
      axi_awaddr  <= 0;
      axi_wvalid  <= 0;
      axi_wdata   <= 0;
      axi_bready  <= 0;
    end else begin
      case (out_state)
        /***********************************************
        * 最初に, コンテストサーバに 0xAA を送り付ける.
        *
        */
        OUT_WAIT_FOR_0XAA:
        begin
          if (stat_reg[2:2] && stat_reg_new) begin
            out_state <= OUT_DATA_A_FOR_0XAA;
          end
        end
        OUT_DATA_A_FOR_0XAA:
        begin
          axi_wvalid  <= 1;
          axi_awvalid <= 1;
          axi_wdata   <= 32'haa;
          axi_awaddr  <= tx_fifo_addr;
          out_state   <= OUT_DATA_B;
        end
        /***********************************************
        * 以下, 通常のOUT命令実行.
        *
        */
        OUT_WAIT:
        begin
          out_state <= OUT_DATA_A;
          /*
          if (stat_reg[2:2] && stat_reg_new) begin
            out_state <= OUT_DATA_A;
          end
          */
        end
        OUT_DATA_A:
        begin
          if (out_req) begin
            axi_wvalid  <= 1;
            axi_awvalid <= 1;
            axi_wdata   <= out_data;
            axi_awaddr  <= tx_fifo_addr;
            out_state   <= OUT_DATA_B;
          end
        end
        OUT_DATA_B:
        begin
          if (axi_wready&axi_awready) begin
            axi_wvalid  <= 0;
            axi_awvalid <= 0;
            axi_bready  <= 1;
            out_state   <= OUT_DATA_D;
          end else if (axi_wready) begin
            axi_wvalid  <= 0;
            out_state   <= OUT_DATA_C1;
          end else if (axi_awready) begin
            axi_awvalid <= 0;
            out_state   <= OUT_DATA_C2;
          end
        end
        OUT_DATA_C1:
        begin
          if (axi_awready) begin
            axi_awvalid <= 0;
            axi_bready  <= 1;
            out_state   <= OUT_DATA_D;
          end
        end
        OUT_DATA_C2:
        begin
          if (axi_wready) begin
            axi_wvalid  <= 0;
            axi_bready  <= 1;
            out_state   <= OUT_DATA_D;
          end
        end
        OUT_DATA_D:
        begin
          if (axi_bvalid) begin
            axi_bready  <= 0;
            out_state   <= OUT_WAIT;
          end
        end
        default:
        begin
          out_state <= OUT_WAIT;
        end
      endcase
    end
  end
endmodule

module io_data_in #(
  parameter INIT_POINTER         =    0,
  parameter HIGH_POINTER         =   10,
  parameter DEBUG_IGNORE_IN_BUSY = 1'b0
) (
  output wire              axi_arvalid,
  input wire               axi_arready,
  output wire[31:0]        axi_araddr,
  output wire[2:0]         axi_arprot,
  // read data channel
  input wire               axi_rvalid,
  output wire              axi_rready,
  input wire [31:0]        axi_rdata,
  input wire [1:0]         axi_rresp,

  input wire [`ADDR_W-1:0] consumer_pointer,
  output wire[31:0]        stat_reg,
  output wire              stat_reg_new,
  output wire[`ADDR_W-1:0] mem_addr,
  output wire[`WORD_W-1:0] mem_data,
  output wire              mem_we,
  output wire              in_busy,
  input wire               clk,
  input wire               rstn
);
  wire [`WORD_W-1:0] mem_data_reg;
  wire               mem_data_valid;

  wire [`ADDR_W-1:0] prod_pointer;

  assign in_busy = (DEBUG_IGNORE_IN_BUSY==1'b1) ? 0 : (consumer_pointer==prod_pointer);

  io_data_fetch io_data_fetch_1 (
    .axi_arvalid    (axi_arvalid),
    .axi_arready    (axi_arready),
    .axi_araddr     (axi_araddr),
    .axi_arprot     (axi_arprot),
    .axi_rvalid     (axi_rvalid),
    .axi_rready     (axi_rready),
    .axi_rdata      (axi_rdata),
    .axi_rresp      (axi_rresp),
    .stat_reg       (stat_reg),
    .stat_reg_new   (stat_reg_new),
    .mem_data_reg   (mem_data_reg),
    .mem_data_valid (mem_data_valid),
    .clk            (clk),
    .rstn           (rstn)
  );

  io_data_store #(
    INIT_POINTER,
    HIGH_POINTER
  ) io_data_store_1 (
    .mem_data_reg   (mem_data_reg),
    .mem_data_valid (mem_data_valid),
    .prod_pointer   (prod_pointer),
    .mem_addr       (mem_addr),
    .mem_data       (mem_data),
    .mem_we         (mem_we),
    .clk            (clk),
    .rstn           (rstn)
  );
endmodule

module io_data_fetch (
  output reg               axi_arvalid,
  input wire               axi_arready,
  output reg [31:0]        axi_araddr,
  output reg [2:0]         axi_arprot,
  // read data channel
  input wire               axi_rvalid,
  output reg               axi_rready,
  input wire [31:0]        axi_rdata,
  input wire [1:0]         axi_rresp,

  output reg [31:0]        stat_reg,
  output reg               stat_reg_new,
  output reg [`WORD_W-1:0] mem_data_reg,
  output reg               mem_data_valid,
  
  input wire clk,
  input wire rstn
);

  localparam rx_fifo_addr  = 32'd0;
  localparam stat_reg_addr = 32'd8;

  assign axi_arprot = 0;

  reg [ 1:0] data_position;

  enum {
    FETCH_WAIT,
    FETCH_STATUS_A,
    FETCH_STATUS_B,
    FETCH_DATA_A,
    FETCH_DATA_B,
    FETCH_ARRANGE_DATA
  } fetch_state;

  always @(posedge clk) begin
    if (~rstn) begin
      fetch_state    <= FETCH_STATUS_A;
      axi_arvalid    <= 0;
      axi_rready     <= 0;
      axi_araddr     <= 0;
      mem_data_reg   <= 0;
      mem_data_valid <= 0;
      data_position  <= 0;
      stat_reg       <= 0;
      stat_reg_new   <= 0;
    end else begin
      mem_data_valid <= 0;
      stat_reg_new   <= 0;

      case (fetch_state)
        /**************************
        *    FETCH STATUS PHASE   *
        **************************/
        FETCH_STATUS_A:
        begin
          axi_arvalid <= 1;
          axi_araddr  <= stat_reg_addr;
          fetch_state <= FETCH_STATUS_B;
        end
        FETCH_STATUS_B:
        begin
          if (axi_arready) begin
            axi_arvalid <= 0;
            axi_rready  <= 1;
            fetch_state <= FETCH_DATA_A;
          end
        end
        /**************************
        *     FETCH DATA PHASE    *
        **************************/
        FETCH_DATA_A:
        begin
          if (axi_rvalid) begin
            axi_rready    <= 0;
            stat_reg      <= axi_rdata;
            stat_reg_new  <= 1;

            // axi_rdata[0:0] has the validity of rx-fifo data.
            fetch_state <=(axi_rdata[0]) ? FETCH_DATA_B : FETCH_STATUS_A;
            axi_araddr  <=(axi_rdata[0]) ? rx_fifo_addr : stat_reg_addr ;
            axi_arvalid <=(axi_rdata[0]);
          end
        end
        FETCH_DATA_B:
        begin
          if (axi_arready) begin
            axi_arvalid <= 0;
            axi_rready  <= 1;
            fetch_state <= FETCH_ARRANGE_DATA;
          end
        end
        /**************************
        *   ARRANGE DATA PHASE    *
        **************************/
        FETCH_ARRANGE_DATA:
        begin
          if (axi_rvalid) begin
            axi_rready    <= 0;

            case (data_position)
              2'b00  :begin mem_data_reg[ 7: 0]<=axi_rdata[7:0];mem_data_valid<=0;end
              2'b01  :begin mem_data_reg[15: 8]<=axi_rdata[7:0];mem_data_valid<=0;end
              2'b10  :begin mem_data_reg[23:16]<=axi_rdata[7:0];mem_data_valid<=0;end
              2'b11  :begin mem_data_reg[31:24]<=axi_rdata[7:0];mem_data_valid<=1;end
              default:begin mem_data_reg[ 7: 0]<=axi_rdata[7:0];mem_data_valid<=0;end
            endcase

            data_position <= data_position + 1;
            fetch_state   <= FETCH_STATUS_A;
          end
        end
        /*******************
        * unexpected value *
        *******************/
        default:
        begin
          fetch_state <= FETCH_STATUS_A;
        end
      endcase
    end
  end
endmodule

module io_data_store #(
  parameter INIT_POINTER = 0,
  parameter HIGH_POINTER =10
) (
  input wire [`WORD_W-1:0] mem_data_reg,
  input wire               mem_data_valid,
  output reg [`ADDR_W-1:0] prod_pointer,
  output reg [`ADDR_W-1:0] mem_addr,
  output reg [`WORD_W-1:0] mem_data,
  output reg               mem_we,
  input wire               clk,
  input wire               rstn
);
  always @(posedge clk) begin
    if (~rstn) begin
      prod_pointer <= INIT_POINTER;
      mem_data     <= 0;
      mem_addr     <= 0;
      mem_we       <= 0;
    end else if (mem_data_valid) begin
      prod_pointer <= prod_pointer + 1;
      mem_data     <= mem_data_reg;
      mem_addr     <= prod_pointer;
      mem_we       <= 1;
    end else begin
      mem_we       <= 0;
    end
  end
endmodule

`default_nettype wire
