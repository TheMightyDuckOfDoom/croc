#!/bin/bash
rm -r flopoco_workspace/*.v

files=$(ls flopoco_workspace/*.vhdl)

for file in $files
do
    basename=$(basename $file .vhdl)
    yosys -p "ghdl --std=08 --ieee=synopsys $file -e $basename; write_verilog flopoco_workspace/$basename.v"
done

