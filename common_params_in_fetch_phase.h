`ifndef COMMON_PARAMS_IN_FETCH_PHASE_H
`define COMMON_PARAMS_IN_FETCH_PHASE_H

// In Fetch Phase
typedef enum {
    S_IGNORE_MEANGLESS_ADD_1, // SはStateのS
    S_IGNORE_MEANGLESS_ADD_2,
    S_OPCODE_1,
    S_OPCODE_2,
    S_OPCODE_3,
    S_MODRM_DEST_RM, // r/mがデスティネーションレジスタ
    S_MODRM_DEST_R,  //   rがデスティネーションレジスタ
    S_MODRM_AS_EFFECTIVE_ADDRESS,
    S_SIB_DEST_RM,
    S_SIB_DEST_R,
    S_DISPLACEMENT,
    S_IMMEDIATE
} fstate;

`endif
