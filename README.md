# CPUEX_x86-64
x86-64のコアを書きたい

対応している命令（x86-64の命令セットのサブセット）
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

micro-opcode

- コア内部で実際に用いられる命令セット
- MIPS32などをもとに独自に構想

| 名前 | 命令         | 意味        | 詳細 |
|:----:|:----         |:----        |:---- |
| ADD  | Add $d,$s,$t | $d=$s+$t    | 整数加算 |
| ADC  | Adc $d,$s,$t | $d=$s+$t+CF | carry付き整数加算 |
| SUB  | Sub $d,$s,$t | $d=$s-$t    | 整数減算 |
