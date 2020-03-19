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

  SS  = 16,
  CS  = 17,
  DS  = 18,
  ES  = 19,
  FS  = 20,
  GS  = 21,
  RIP = 22,
  EFL = 23,
  SCL = 24,
  TMP = 25
} rega_t;

typedef enum {
  MIOP_NOP = 0,
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
  MIOP_L   ,
  MIOP_S   ,
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
  MIOP_MOV ,
  MIOP_MOVI,
  MIOP_CMP ,
  MIOP_CMPI
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


function bmd_t bmd_det (
  input cond_bmd_08,
  input cond_bmd_64
);
begin
  bmd_det = (cond_bmd_08) ? BMD_08:
            (cond_bmd_64) ? BMD_64:
                            BMD_32;
end
endfunction

function [3:0] imm_size_det (
  input cond_one_byte,
  input cond_four_byte
);
begin
  imm_size_det = (cond_one_byte ) ? 1:
                 (cond_four_byte) ? 4:
                                    0;
end
endfunction

function miinst_t make_miinst(
  input miop_t opcode,
  input rega_t d,
  input rega_t s,
  input rega_t t,
  input imm_t  imm,
  input bmd_t  bmd,
  input addr_t pc
);
begin
  make_miinst.op  <= opcode;
  make_miinst.d   <= d;
  make_miinst.s   <= s;
  make_miinst.t   <= t;
  make_miinst.imm <= imm;
  make_miinst.bmd <= bmd;
  make_miinst.pc  <= pc;
end
endfunction

function miinst_t load_on_pop (input rega_t dest,input addr_t pc);
begin
  load_on_pop<=make_miinst(MIOP_L,dest,RSP,0,0,BMD_64,pc);
end
endfunction

function miinst_t addi_on_pop(input addr_t pc);
begin
  addi_on_pop<=make_miinst(MIOP_ADDI,RSP,RSP,`IMM_W'(8),BMD_64,pc);
end
endfunction

function miinst_t addi_on_push(input addr_t pc);
begin
  addi_on_pop<=make_miinst(MIOP_ADDI,RSP,RSP,`IMM_W'(signed'(-8)),BMD_64,pc);
end
endfunction

function miinst_t store_on_push(input rega_t dest,input addr_t pc);
begin
  load_on_pop<=make_miinst(MIOP_S,dest,RSP,0,0,BMD_64,pc);
end
endfunction

function miinst_t pre_jcc (input [3:0] lower_bits_of_inst,input addr_t pc);
begin
  case (lower_bits_of_inst)
    4'h0   :pre_jcc <= make_miinst(MIOP_JO ,0,0,0,0,BMD_32,pc);
    4'h1   :pre_jcc <= make_miinst(MIOP_JNO,0,0,0,0,BMD_32,pc);
    4'h2   :pre_jcc <= make_miinst(MIOP_JB ,0,0,0,0,BMD_32,pc);
    4'h3   :pre_jcc <= make_miinst(MIOP_JAE,0,0,0,0,BMD_32,pc);
    4'h4   :pre_jcc <= make_miinst(MIOP_JE ,0,0,0,0,BMD_32,pc);
    4'h5   :pre_jcc <= make_miinst(MIOP_JNE,0,0,0,0,BMD_32,pc);
    4'h6   :pre_jcc <= make_miinst(MIOP_JBE,0,0,0,0,BMD_32,pc);
    4'h7   :pre_jcc <= make_miinst(MIOP_JA ,0,0,0,0,BMD_32,pc);
    4'h8   :pre_jcc <= make_miinst(MIOP_JS ,0,0,0,0,BMD_32,pc);
    4'h9   :pre_jcc <= make_miinst(MIOP_JNS,0,0,0,0,BMD_32,pc);
    4'ha   :pre_jcc <= make_miinst(MIOP_JP ,0,0,0,0,BMD_32,pc);
    4'hb   :pre_jcc <= make_miinst(MIOP_JNP,0,0,0,0,BMD_32,pc);
    4'hc   :pre_jcc <= make_miinst(MIOP_JL ,0,0,0,0,BMD_32,pc);
    4'hd   :pre_jcc <= make_miinst(MIOP_JGE,0,0,0,0,BMD_32,pc);
    4'he   :pre_jcc <= make_miinst(MIOP_JLE,0,0,0,0,BMD_32,pc);
    default:pre_jcc <= make_miinst(MIOP_JG ,0,0,0,0,BMD_32,pc);
  endcase
end
endfunction

function miinst_t jr(input rega_t d,input addr_t pc);
begin
  jr <= make_miinst(MIOP_JR,d,0,0,0,BMD_32,pc);
end
endfunction

function miinst_t nop(input addr_t pc);
begin
  nop.op  <= MIOP_NOP;
  nop.d   <=        0;
  nop.s   <=        0;
  nop.t   <=        0;
  nop.imm <=        0;
  nop.bmd <=        0;
  nop.pc  <=       pc;
end
endfunction

function fstate make_state(
  input fsust_obj  o,
  input fsubst_dst d,
  input fsubst_grp g
);
begin
  make_state.obj  <= o;
  make_state.dst  <= d;
  make_state.grp  <= g;
end
endfunction

