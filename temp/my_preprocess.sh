#!/bin/bash

cat ./$1.s |
  sed -e 's/_R_10/%r14/g' |
  sed -e 's/_R_11/%r14/g' |
  sed -e 's/_R_ax/%rax/g' |
  sed -e 's/_R_0/%rbx/g'  |
  sed -e 's/_R_1/%rcx/g'  |
  sed -e 's/_R_dx/%rdx/g' |
  sed -e 's/_R_2/%rsi/g'  |
  sed -e 's/_R_3/%rdi/g'  |
  sed -e 's/_R_bp/%rbp/g'  |
  sed -e 's/_R_sp/%rsp/g' |
  sed -e 's/_R_4/%r8/g'   |
  sed -e 's/_R_5/%r9/g'   |
  sed -e 's/_R_6/%r10/g'  |
  sed -e 's/_R_7/%r11/g'  |
  sed -e 's/_R_8/%r12/g'  |
  sed -e 's/_R_9/%r13/g'  > ./$1_preprocessed.s
