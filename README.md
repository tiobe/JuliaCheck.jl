# JuliaCheck

JuliaCheck is a code checker for the Julia language. It checks input files against a dynamic set of rules (loaded from folder `checks`), parsing those files with [JuliaSyntax](https://github.com/JuliaLang/JuliaSyntax.jl).

Invocation of JuliaCheck:
```
usage: JuliaCheck.jl [--enable RULES [RULES...]] [-v] [--ast] [--llt]
                     [--output OUTPUT] [--outputfile OUTPUTFILE]
                     [--version] [-h] infiles...

Code checker for Julia programming language.

positional arguments:
  infiles               One or more Julia files to check with
                        available rules.

optional arguments:
  --enable RULES [RULES...]
                        List of rules to check on the given files.
  -v, --verbose         Print debugging information.
  --ast                 Print syntax tree for each input file.
  --llt                 Print green tree for each input file.
  --version             show version information and exit
  --output OUTPUT       Select output type. Allowed types:
                        highlighting, json, simple. (default:
                        "highlighting")
  --outputfile OUTPUTFILE
                        Write output to the given file. If left empty,
                        this will write to command line.
  -h, --help            show this help message and exit
```

When using the list of enabled rules, you must use `--` to separate that list from the list of files to be checked. E.g.:
```
julia src/JuliaCheck.jl --enable module-name-casing single-module-file -- file_to_check.jl
```

The equivalent call from Julia's REPL, after importing JuliaCheck, would be:
```
JuliaCheck.main(["--enable", "module-name-casing", "single-module-file", "--", "file_to_check.jl"])
```

If no rules are specified in the command line, all rules are checked.
