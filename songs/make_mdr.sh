#!/bin/sh

BINDIR=../bin

if [ $# -lt 1  ]
then
	echo "Usage: $0 <file> [DEBUG]"
	exit 1
fi

NAME=${1%.*}
MML=$1

# $MMLで指定されたファイル名が存在しない
if [ ! -e $MML ]
then
	MML=${NAME}.mml
fi

# コンパイル
${BINDIR}/mmckc -i $MML

# アセンブルを行う
${BINDIR}/pceas -raw mdrvhdr.asm

if [ ! -e mdrvhdr.pce ]
then
	exit 1
fi

mv mdrvhdr.pce ${NAME}.MDR

if [ "x${2}" != "xDEBUG" ]
then
	rm ${NAME}.h
	rm define.inc
	rm effect.h
fi
