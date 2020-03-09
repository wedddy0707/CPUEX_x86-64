# CPUEX_x86-64
x86-64のコアを書きたい

## レジスタ
| 番地 | 名前 | 略称 | 元からx86に... | 説明 |
| ----:|:----:|:----:|:----:          |:---- |
|  0 | アキュムレータレジスタ  | AX/EAX/RAX | ある ||
|  1 | カウンタレジスタ        | CX/ECX/RCX | ある ||
|  2 | データレジスタ          | DX/EDX/RDX | ある ||
|  3 | ベースレジスタ          | BX/EBX/RBX | ある ||
|  4 | スタックポインタレジスタ| SP/ESP/RSP | ある ||
|  5 | スタックベースポインタレジスタ | BP/EBP/RBP |ある||
|  6 | ソースレジスタ          | SI/ESI/RSI | ある ||
|  7 | デスティネーションレジスタ | DI/EDI/RDI | ある ||
|  8 |-|-|ある|REX.Wで指定できるレジスタ.用途自由|
|  9 |-|-|ある|REX.Wで指定できるレジスタ.用途自由|
| 10 |-|-|ある|REX.Wで指定できるレジスタ.用途自由|
| 11 |-|-|ある|REX.Wで指定できるレジスタ.用途自由|
| 12 |-|-|ある|REX.Wで指定できるレジスタ.用途自由|
| 13 |-|-|ある|REX.Wで指定できるレジスタ.用途自由|
| 14 |-|-|ある|REX.Wで指定できるレジスタ.用途自由|
| 15 |-|-|ある|REX.Wで指定できるレジスタ.用途自由|
| 16 | スタックセグメント | SS | ある | 事実上無効となったレジスタ |
| 17 | コードセグメント   | CS | ある | 同上 |
| 18 | データセグメント   | DS | ある | 同上 |
| 19 | エクストラセグメント |ES| ある | 同上 |
| 20 | Fセグメント        | FS | ある | 現代でも使われることがあるらしい... |
| 21 | Gセグメント        | GS | ある | 同上 |
| 22 | 命令ポインタレジスタ | IP/EIP/RIP |ある| PC(プログラムカウンタ)のこと. x86の命令がこのレジスタに触れることは原則できない. アドレスを与えたのは扱いやすくするため. |
| 23 | EFLAGSレジスタ | EFLAGS |ある| 算術論理演算の結果得られた状態など（carry, overflow, parityなど）を保持. アドレスを与えたのは扱いやすくするため. |
| 24 | スケーリングレジスタ | SCL | ない | x86の命令からは完全に秘匿される. micro-opcodeが利用. SIB byteで指定されたスケーリングの結果を一時的に保存しておくのに使う. |
| 25 | テンポラリレジスタ | TMP | ない | x86の命令からは完全に秘匿される. Loadしてきたデータを一時的に保持したり、Storeするデータを一時的に保持しておきたいときに使う. |
| 26 | - | - | ない | 将来の自分がout-of-orderを実装してくれることを期待して、余分なレジスタを用意. |
| 27 | - | - | ない | 同上 |
| 28 | - | - | ない | 同上 |
| 29 | - | - | ない | 同上 |
| 30 | - | - | ない | 同上 |
| 31 | - | - | ない | 同上 |
## 対応している命令（x86-64の命令セットのサブセット）
| 命令 | 説明                               |
|:----:| :----                              |
| ADD  | 整数加算                           |
| ADC  | carry付き整数加算                  |
| SUB  | 整数減算                           |
| SBB  | borrow付き整数減算                 |
| MOV  | move                               |
| AND  | bitごとのAND                       |
|  OR  | bitごとのOR                        |
| XOR  | bitごとのXOR                       |
| PUSH | Stackにpushする                    |
| POP  | Stackからpopする                   |
| Jcc  | 条件分岐                           |
| CALL | 関数呼び出し                       |
| RET  | 関数終了                           |
| CMP  | 比較（subの結果をeflagsに保存）    |
| TEST | 論理比較（andの結果をeflagsに保存）|



## micro-opcode

- コア内部で実際に用いられる命令セット
- MIPS32などをもとに独自に構想

| 名前 | 命令         | 意味        | 詳細 |
|:----:|:----         |:----        |:---- |
| NOP  | -            | -           | NOP命令. |
| ADD  | Add $d,$s,$t | $d=$s+$t    | 整数加算 |
| SUB  | Sub $d,$s,$t | $d=$s-$t    | 整数減算 |
| MUL  | Mul $d,$s,$t | $d=$s*$t    | 対応予定 |
| DIV  | Div $d,$s,$t | $d=$s/$t    | 対応予定 |
| AND  | And $d,$s,$t | $d=$s&$t    | bit AND  |
| OR   | Or  $d,$s,$t | $d=$s|$t    | bit OR   |
| XOR  | Xor $d,$s,$t | $d=$s^$t    | bit XOR  |
| SLL  | Sll $d,$s,$t | $d=$s<<$t   | 左論理シフト |
| SRL  | Srl $d,$s,$t | $d=$s>>$t   | 右論理シフト |
| SRA  | Sra $d,$s,$t | $d=$s>>>$t  | 右算術シフト |
| ADC  | Adc $d,$s,$t | $d=$s+$t+CF | carry付き整数加算 |
| SBB  | Sbb $d,$s,$t | $d=$s-($t+CF)|borrow付き整数減算|
| MOV  | Mov $d,--,$t | $d=$t       | $tから$dに移すことに注意.諸事情あってこうなっている. |
| CMP  | Cmp --,$s,$t | Set eflags according to $s-$t | 減算の結果からEflagsを更新する. 減算の結果自体は保存しない. |
| TEST | Test --,$s,$t| Set eflags according to $s&$t | 論理積の結果について上と同様のことを行う. |
| ADDI | Addi $d,$s,C | $d=$s+C     | 定数整数加算 |
| SUBI | Subi $d,$s,C | $d=$s-C     | 定数整数減算 |
| MULI | Muli $d,$s,C | $d=$s*C     | 対応予定 |
| DIVI | Divi $d,$s,C | $d=$s/C     | 対応予定 |
| ANDI | Andi $d,$s,C | $d=$s&C     | 定数bit AND  |
| OR I | Or i $d,$s,C | $d=$s|C     | 定数bit OR   |
| XORI | Xori $d,$s,C | $d=$s^C     | 定数bit XOR  |
| SLLI | Slli $d,$s,C | $d=$s<<C    | 定数左論理シフト |
| SRLI | Srli $d,$s,C | $d=$s>>C    | 定数右論理シフト |
| SRAI | Srai $d,$s,C | $d=$s>>>C   | 定数右算術シフト |
| ADCI | Adci $d,$s,C | $d=$s+C+CF  | carry付き定数整数加算 |
| SBBI | Sbbi $d,$s,C | $d=$s-(C+CF)|borrow付き定数整数減算|
| MOVI | Mov $d,--, C | $d=$t       | Cを$dに移す. 0-extended. |
| CMPI | Cmp --,$s, C | Set eflags according to $s-C | 減算の結果からEflagsを更新する. 減算の結果自体は保存しない. |
| TESTI| Test --,$s,C | Set eflags according to $s&C | 論理積の結果について上と同様のことを行う. |
| L    | L    $d,$s,C | $d=[$s+C]   | Load  |
| S    | S    $d,$s,C | [$s+C]=$d   | Store |
| J    | J   C        | Jump to [RIP+C] | 無条件分岐 |
| JR   | Jr  $d       | Jump to [$d]    | 無条件分岐 |
| JA   | Ja  C        | Jump to [RIP+C] if above            | 条件分岐 |
| JAE  | Jae C        | Jump to [RIP+C] if above or equal   | 条件分岐 |
| JB   | Jb  C        | Jump to [RIP+C] if below            | 条件分岐 |
| JBE  | Jbe C        | Jump to [RIP+C] if below or equal   | 条件分岐 |
| JC   | Jc  C        | Jump to [RIP+C] if carry            | 条件分岐 |
| JE   | Je  C        | Jump to [RIP+C] if equal            | 条件分岐 |
| JG   | Jg  C        | Jump to [RIP+C] if greater          | 条件分岐 |
| JGE  | Jge C        | Jump to [RIP+C] if greater or equal | 条件分岐 |
| JL   | Jl  C        | Jump to [RIP+C] if less             | 条件分岐 |
| JLE  | Jle C        | Jump to [RIP+C] if less or equal    | 条件分岐 |
| JO   | Jo  C        | Jump to [RIP+C] if overflow         | 条件分岐 |
| JP   | Jp  C        | Jump to [RIP+C] if parity           | 条件分岐 |
| JS   | Js  C        | Jump to [RIP+C] if sign             | 条件分岐 |
| JNE  | Jne C        | Jump to [RIP+C] if not equal        | 条件分岐 |
| JNP  | Jnp C        | Jump to [RIP+C] if not parity       | 条件分岐 |
| JNS  | Jns C        | Jump to [RIP+C] if not sign         | 条件分岐 |
| JNO  | Jno C        | Jump to [RIP+C] if not overflow     | 条件分岐 |
| JCX  | Jcx C        | Jump to [RIP+C] if RCX=0            | 条件分岐 |
