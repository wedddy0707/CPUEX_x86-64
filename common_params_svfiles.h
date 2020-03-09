`include "common_params.h"

typedef logic [`INST_W    -1:0] inst_t;
typedef logic [`IMM_W     -1:0] imm_t ;
typedef logic [`ADDR_W    -1:0] addr_t;
typedef logic [`REG_W/8   -1:0]   we_t;
typedef logic [`NAME_W    -1:0] name_t;
typedef logic [`REG_W     -1:0] reg_t ;

typedef enum logic[`REG_ADDR_W-1:0] {
  RAX = 0,
  RCX = 1,
  RDX = 2,
  RBX = 3,
  RSP = 4,
  RBP = 5,
  RSI = 6,
  RDI = 7,

  RIP = 16,
  EFL = 17,
  SCL = 18,
  TMP = 19
} rega_t;

typedef enum {
  MIOP_ADD ,
  MIOP_SUB ,
  MIOP_MUL ,
  MIOP_DIV ,
  MIOP_AND ,
  MIOP_OR  ,
  MIOP_XOR ,
  MIOP_SLL ,
  MIOP_SRL ,
  MIOP_SRA ,
  MIOP_ADC ,
  MIOP_SBB ,
  MIOP_ADDI,
  MIOP_SUBI,
  MIOP_MULI,
  MIOP_DIVI,
  MIOP_ANDI,
  MIOP_ORI ,
  MIOP_XORI,
  MIOP_SLLI,
  MIOP_SRLI,
  MIOP_SRAI,
  MIOP_ADCI,
  MIOP_SBBI,
  MIOP_LB  ,
  MIOP_LW  ,
  MIOP_LD  ,
  MIOP_LQ  ,
  MIOP_SB  ,
  MIOP_SW  ,
  MIOP_SD  ,
  MIOP_SQ  ,
  MIOP_J   ,
  MIOP_JR  ,
  MIOP_JA  ,
  MIOP_JAE ,
  MIOP_JB  ,
  MIOP_JBE ,
  MIOP_JC  ,
  MIOP_JE  ,
  MIOP_JG  ,
  MIOP_JGE ,
  MIOP_JL  ,
  MIOP_JLE ,
  MIOP_JO  ,
  MIOP_JP  ,
  MIOP_JS  ,
  MIOP_JNE ,
  MIOP_JNP ,
  MIOP_JNS ,
  MIOP_JNO ,
  MIOP_JCX ,
  MIOP_NOP ,
  MIOP_MOV ,
  MIOP_MOVI,
  MIOP_CMP ,
  MIOP_CMPI,
  MIOP_L,
  MIOP_S
} miop_t;

typedef enum logic[1:0] {
  BMD_08,
  BMD_16,
  BMD_32,
  BMD_64
} bmd_t;

typedef struct packed {
  miop_t op ;
  rega_t d  ;
  rega_t s  ;
  rega_t t  ;
  imm_t  imm;
  bmd_t  bmd;
  addr_t pc ;
} miinst_t;

// In Fetch Phase
typedef enum {
  IGNORE_MEANGLESS_ADD_1,
  IGNORE_MEANGLESS_ADD_2,
  OPCODE_1,
  OPCODE_2,
  OPCODE_3,
  MODRM,
  SIB,
  DISPLACEMENT,
  IMMEDIATE
} fsubst_obj;

typedef enum {
  DST_RM,
  DST_R
} fsubst_dst;

typedef enum {
  GRP_0, //どのグループにも属さないということ. 
  GRP_1,
  GRP_1A,
  GRP_2,
  GRP_3,
  GRP_4,
  GRP_5,
  GRP_6,
  GRP_7,
  GRP_8,
  GRP_9,
  GRP_10,
  GRP_11,
  GRP_LEA
} fsubst_grp;

typedef struct packed {
  fsubst_obj  obj; // 対象
  fsubst_dst  dst; // デスティネーション
  fsubst_grp  grp; // グループ
} fstate;

typedef struct packed {
  logic [      2:0] size;
  logic [`MQ_N-1:0] to  ;
  logic [      2:0] cnt ;
} const_info_t;

// For Register Usage Table
typedef struct packed {
  logic from_gd;
  logic from_fd;
  logic   to_gd;
  logic   to_fd;
  logic from_gs;
  logic from_fs;
  logic from_gt;
  logic from_ft;
  logic from_ef;
  logic   to_ef;
  rega_t      d;
  rega_t      s;
  rega_t      t;
} rut_t;

// For Forward
typedef struct packed {
  logic d;
  logic s;
  logic t;
} fwd_t;

// For Pipeline Registers

typedef struct packed {
  miinst_t miinst;
  reg_t    d;
  reg_t    s;
  reg_t    t;
} de_reg_t;

typedef struct packed {
  miinst_t miinst;
  reg_t    d;
} ew_reg_t;

typedef struct packed {
  logic    eflags_update;
  reg_t    eflags;
  logic    be;
  addr_t   bd;
} ew_sig_t;

