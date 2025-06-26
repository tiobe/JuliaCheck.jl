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
for test_file in test/*.jl; do
    val_file=${test_file%.jl}.val
    [ -r "$val_file" ] || continue
    outfile=$( mktemp )
    julia $JuliaCheck $test_file > $outfile
    # This used to be done with `diff -q $val_file <( julia ... )`, but it caused
    # an error with one of the input files. See here:
    # https://github.com/julia-vscode/SymbolServer.jl/pull/120#issuecomment-2871798605
    if diff -q $val_file $outfile > /dev/null 2>&1
    then
        echo "File '$test_file' checked."
    else
        echo " -- Test failed for file '$test_file'."
        ((err_code++))
    fi
done
exit $err_code
