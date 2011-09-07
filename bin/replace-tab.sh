#!/bin/ksh

for iter in *
do
    echo ${iter}
    sed 's/	/  /g' "${iter}" > filename.notabs && mv filename.notabs "${iter}"
done
