#!/bin/bash
rm -rf flopoco_workspace
mkdir flopoco_workspace
cd flopoco_workspace

PWD=$(pwd)

docker run --rm=true -v $PWD:/flopoco_workspace flopoco:debian-5.0.0 IEEEFPAdd we=8 wf=23 frequency=50

csplit -z flopoco.vhdl /end\ architecture\;/ '{*}' -f flopoco_ --suppress-matched -s

files=$(ls flopoco_*)

for file in $files
do
    # If file does not contain 'architecture arch of ' delete it
    if ! grep -q 'architecture arch of ' $file
    then
        rm $file
        continue
    fi

    echo 'end architecture;' >> $file

    archname=$(grep 'architecture arch of ' $file | sed 's/.*architecture arch of \(.*\) is.*/\1/')
    mv $file $archname.vhdl
done

rm -f flopoco.vhdl
