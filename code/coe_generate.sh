#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <inputfile> <outputfile>" 1>&2
  exit 1
fi

cd `dirname $1`
gcc -c `basename $1`
cd -
mv ${1%%.c}.o ./
ld pick_up_text.ld `basename ${1%%.c}.o`
python elf2coe.py a.out $2

echo ""
echo ""
echo ""
echo ""
echo "GENERATED INSTRUCTION SEQUENCE:"
#objdump -d `basename ${1%%.c}.o`
objdump -d a.out

echo ""
echo ""
echo ""
echo ""
echo "GENERATED COE FILE:"
cat $2

rm `basename ${1%%.c}.o` a.out
