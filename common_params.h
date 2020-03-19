`ifndef COMMON_PARAMS_H
`define COMMON_PARAMS_H

`define NAME_W (6*8)

`define DATA_W 64 // メモリのデータ幅
`define ADDR_W 32
`define INST_W  8

`define REG_W       64
`define REG_ADDR_W   5
`define REG_N       (2**`REG_ADDR_W)
`define MICRO_W      7
`define MQ_N_W       3
`define MQ_N        (2**(`MQ_N_W))
`define DQ_N_W       4
`define DQ_N        (2**(`DQ_N_W))
`define IMM_W       32

`define EFLAGS_CF   (`REG_W'd0)   // キャリ
`define EFLAGS_PF   (`REG_W'd2)   // パリティ
`define EFLAGS_AF   (`REG_W'd4)   // 調整
`define EFLAGS_ZF   (`REG_W'd6)   // ゼロ
`define EFLAGS_SF   (`REG_W'd7)   // 符号
`define EFLAGS_TF   (`REG_W'd8)   // 
`define EFLAGS_IF   (`REG_W'd9)
`define EFLAGS_DF   (`REG_W'd10)
`define EFLAGS_OF   (`REG_W'd11)
`define EFLAGS_IOPL (`REG_W'd12)
`define EFLAGS_NT   (`REG_W'd14)
`define EFLAGS_RF   (`REG_W'd16)
`define EFLAGS_VM   (`REG_W'd17)
`define EFLAGS_AC   (`REG_W'd18)
`define EFLAGS_VIF  (`REG_W'd19)
`define EFLAGS_VIP  (`REG_W'd20)
`define EFLAGS_ID   (`REG_W'd21)

`define MQ_SCALE (`MQ_N_W'd0) // SIBに応じてシフトを実行する
`define MQ_LOAD  (`MQ_N_W'd1) // ModR/Mに応じてLoad又は即値を$tempに保持
`define MQ_ARITH (`MQ_N_W'd2) // 算術（論理）演算の実行
`define MQ_STORE (`MQ_N_W'd3) // ModR/Mに応じてStore
`define MQ_RSRV1 (`MQ_N_W'd4)
`define MQ_RSRV2 (`MQ_N_W'd5)
`define MQ_RSRV3 (`MQ_N_W'd6)
`define MQ_RSRV4 (`MQ_N_W'd7)


`endif
