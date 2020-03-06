`include "common_params.h"

typedef logic [`INST_W    -1:0] inst_t;
typedef logic [`IMM_W     -1:0] imm_t ;
typedef logic [`ADDR_W    -1:0] addr_t;
typedef logic [`NAME_W    -1:0] name_t;
typedef logic [`REG_ADDR_W-1:0] rega_t;
typedef logic [            3:0] rex_t ;

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
  miop_t opcode;
  rega_t d     ;
  rega_t s     ;
  rega_t t     ;
  imm_t  imm   ;
  bmd_t  bmd   ;
  addr_t pc    ;
} miinst_t;

// In Fetch Phase
typedef enum {
  S_IGNORE_MEANGLESS_ADD_1, // SはStateのS
  S_IGNORE_MEANGLESS_ADD_2,
  S_OPCODE_1,
  S_OPCODE_2,
  S_OPCODE_3,
  S_MODRM,
  S_SIB,
  S_DISPLACEMENT,
  S_IMMEDIATE
} fstate;

typedef enum {
  MODRM_DEST_RM_GRP_1,
  MODRM_DEST_RM_GRP_1A,
  MODRM_DEST_RM_GRP_2,
  MODRM_DEST_RM_GRP_3,
  MODRM_DEST_RM_GRP_4,
  MODRM_DEST_RM_GRP_5,
  MODRM_DEST_RM_GRP_6,
  MODRM_DEST_RM_GRP_7,
  MODRM_DEST_RM_GRP_8,
  MODRM_DEST_RM_GRP_9,
  MODRM_DEST_RM_GRP_10,
  MODRM_DEST_RM_GRP_11,
  MODRM_DEST_RM_DEFAULT,
  MODRM_DEST_R_DEFAULT,
  SIB_DEST_RM,
  SIB_DEST_R,
  DISPLACEMENT_1,
  DISPLACEMENT_2,
  DISPLACEMENT_3,
  DISPLACEMENT_4,
  IMMEDIATE_1,
  IMMEDIATE_2,
  IMMEDIATE_3,
  IMMEDIATE_4
} fsubst;
