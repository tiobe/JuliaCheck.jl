#!/bin/bash

DIR=$( dirname "${BASH_SOURCE[0]}" )
DIR=$( realpath -e "$DIR/.." )
cd "$DIR" ||  {
    echo "Target directory '$DIR' not accessible!" >&2
    exit -1
}

JuliaCheck=src/JuliaCheck.jl
[ -r $JuliaCheck ] || {
    echo "$JuliaCheck not found!" >&2
    exit -1
}

err_code=0
for test_file in tests/*.jl; do
    val_file=${test_file%.jl}.val
    [ -r "$val_file" ] || continue
    if diff $val_file <( julia $JuliaCheck $test_file ); then
        echo "File '$test_file' checked."
    else
        ((err_code++))
    fi
done
exit $err_code
