`ifndef COMMON_PARAMS_H
`define COMMON_PARAMS_H

`define DATA_W 64 // メモリのデータ幅
`define ADDR_W 32
`define INST_W  8

`define REG_W       64
`define REG_ADDR_W   5
`define REG_N       (2**`REG_ADDR_W)
`define MICRO_W      7
`define OPCODE_W    (`MICRO_W) // `MICRO_W のエイリアス
`define MICRO_Q_N_W  3
`define MICRO_Q_N   (2**(`MICRO_Q_N_W))
`define DEC_Q_N_W    4
`define DEC_Q_N     (2**(`DEC_Q_N_W))
`define IMM_W       32
`define DISP_W      32
`define BIT_MODE_W   2

`define RAX_ADDR (`REG_ADDR_W'd0)
`define RCX_ADDR (`REG_ADDR_W'd1)
`define RDX_ADDR (`REG_ADDR_W'd2)
`define RBX_ADDR (`REG_ADDR_W'd3)
`define RSP_ADDR (`REG_ADDR_W'd4)
`define RBP_ADDR (`REG_ADDR_W'd5)
`define RSI_ADDR (`REG_ADDR_W'd6)
`define RDI_ADDR (`REG_ADDR_W'd7)
`define ZER_ADDR (`REG_ADDR_W'd16) // ゼロレジスタ
`define RIP_ADDR (`REG_ADDR_W'd17) // 命令ポインタレジスタ
`define EFL_ADDR (`REG_ADDR_W'd18) // EFLAGS
`define SCL_ADDR (`REG_ADDR_W'd19)
`define TMP_ADDR (`REG_ADDR_W'd20)

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

`define MICRO_Q_SCALE   (`MICRO_Q_N_W'd0) // SIBに応じてシフトを実行する
`define MICRO_Q_LOAD    (`MICRO_Q_N_W'd1) // ModR/Mに応じてLoad又は即値を$tempに保持
`define MICRO_Q_ARITH   (`MICRO_Q_N_W'd2) // 算術（論理）演算の実行
`define MICRO_Q_STORE   (`MICRO_Q_N_W'd3) // ModR/Mに応じてStore
`define MICRO_Q_RSRV1   (`MICRO_Q_N_W'd4)
`define MICRO_Q_RSRV2   (`MICRO_Q_N_W'd5)
`define MICRO_Q_RSRV3   (`MICRO_Q_N_W'd6)

`define MICRO_ADD    (`MICRO_W'b0000011)
`define MICRO_SUB    (`MICRO_W'b0001011)
`define MICRO_MUL    (`MICRO_W'b0010011)
`define MICRO_DIV    (`MICRO_W'b0011011)
`define MICRO_AND    (`MICRO_W'b0100011)
`define MICRO_OR     (`MICRO_W'b0101011)
`define MICRO_XOR    (`MICRO_W'b0110011)
`define MICRO_SLL    (`MICRO_W'b0111011)
`define MICRO_SRL    (`MICRO_W'b1000011)
`define MICRO_SRA    (`MICRO_W'b1001011)
`define MICRO_ADDI   (`MICRO_W'b0000111)
`define MICRO_SUBI   (`MICRO_W'b0001111)
`define MICRO_MULI   (`MICRO_W'b0010111)
`define MICRO_DIVI   (`MICRO_W'b0011111)
`define MICRO_ANDI   (`MICRO_W'b0100111)
`define MICRO_ORI    (`MICRO_W'b0101111)
`define MICRO_XORI   (`MICRO_W'b0110111)
`define MICRO_SLLI   (`MICRO_W'b0111111)
`define MICRO_SRLI   (`MICRO_W'b1000111)
`define MICRO_SRAI   (`MICRO_W'b1001111)
`define MICRO_LB     (`MICRO_W'b0001001)
`define MICRO_LW     (`MICRO_W'b0010001)
`define MICRO_LD     (`MICRO_W'b0100001)
`define MICRO_LQ     (`MICRO_W'b1000001)
`define MICRO_SB     (`MICRO_W'b0001101)
`define MICRO_SW     (`MICRO_W'b0010101)
`define MICRO_SD     (`MICRO_W'b0100101)
`define MICRO_SQ     (`MICRO_W'b1000101)
`define MICRO_J      (`MICRO_W'b0000010)
`define MICRO_JR     (`MICRO_W'b0000110)
`define MICRO_JA     (`MICRO_W'b0001010)
`define MICRO_JAE    (`MICRO_W'b0001110)
`define MICRO_JB     (`MICRO_W'b0010010)
`define MICRO_JBE    (`MICRO_W'b0010110)
`define MICRO_JC     (`MICRO_W'b0011010)
`define MICRO_JE     (`MICRO_W'b0100010)
`define MICRO_JG     (`MICRO_W'b0100110)
`define MICRO_JGE    (`MICRO_W'b0101010)
`define MICRO_JL     (`MICRO_W'b0101110)
`define MICRO_JLE    (`MICRO_W'b0110010)
`define MICRO_JO     (`MICRO_W'b0110110)
`define MICRO_JP     (`MICRO_W'b0111010)
`define MICRO_JS     (`MICRO_W'b0111110)
`define MICRO_JNE    (`MICRO_W'b1000010)
`define MICRO_JNP    (`MICRO_W'b1000110)
`define MICRO_JNS    (`MICRO_W'b1001010)
`define MICRO_JNO    (`MICRO_W'b1001110)
`define MICRO_JCX    (`MICRO_W'b1010010)
`define MICRO_NOP    (`MICRO_W'b0000000)
`define MICRO_MOV    (`MICRO_W'b0001000)
`define MICRO_MOVI   (`MICRO_W'b0001100)
`define MICRO_CMP    (`MICRO_W'b0010000)
`define MICRO_CMPI   (`MICRO_W'b0010100)
`define MICRO_LEA    (`MICRO_W'b0011000)
`define MICRO_SEF    (`MICRO_W'b0011100)

`define BIT_MODE_8   (`BIT_MODE_W'd3)
`define BIT_MODE_16  (`BIT_MODE_W'd2)
`define BIT_MODE_32  (`BIT_MODE_W'd1)
`define BIT_MODE_64  (`BIT_MODE_W'd0)

`define ALU_W    8
`define ALU_ADD  0
`define ALU_ADC  1
`define ALU_AND  2
`define ALU_XOR  3
`define ALU_OR   4

`endif
