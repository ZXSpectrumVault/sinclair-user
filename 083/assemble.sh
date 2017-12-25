#! /usr/bin/env bash
python mkbin.py
for infile in decompiled sprite_detect
do
    z80asm -o ${infile}.bin --list=${infile}.list ${infile}.asm
done
md5sum decompiled*bin