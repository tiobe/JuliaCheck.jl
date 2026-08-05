# JuliaCheck

JuliaCheck is a code checker for the Julia language. It checks input files against a dynamic set of rules (loaded from folder `checks`), parsing those files with [JuliaSyntax](https://github.com/JuliaLang/JuliaSyntax.jl).

## Installation
```
using Pkg
Pkg.add("JuliaCheck")
```

Alternatively, install directly from the source repository:
```
using Pkg
Pkg.add(url="https://github.com/tiobe/JuliaCheck.jl")
```

## Usage

JuliaCheck supports the following arguments:
```
usage: julia -m JuliaCheck [--enable RULES [RULES...]] [-v] [--ast] [--llt]
                 [--output OUTPUT] [--outputfile OUTPUTFILE]
                 [--version] [-h] infiles...

Code checker for Julia programming language.

positional arguments:
  infiles               One or more Julia files or directories to
                        check with available rules.

optional arguments:
  --enable RULES [RULES...]
                        List of rules to check on the given files.
  -v, --verbose         Print debugging information.
  --ast                 Print syntax tree for each input file.
  --llt                 Print lossless tree for each input file.
  --output OUTPUT       Select output type. Allowed types:
                        highlighting, json, simple. (default:
                        "highlighting")
  --outputfile OUTPUTFILE
                        Write output to the given file. If left empty,
                        this will write to command line.
  --version             show version information and exit
  -h, --help            show this help message and exit
```

When providing a list of enabled rules, you must use `--` to separate that list from the list of files to be checked.

If the `--enable` option is not provided, all rules are checked.

Example:
```
julia -e 'import Pkg; Pkg.add("JuliaCheck")'
julia -m JuliaCheck --enable module-name-casing single-module-file -- file_to_check.jl
```

The equivalent call from Julia's REPL would be:
```
import JuliaCheck
JuliaCheck.main(["--enable", "module-name-casing", "single-module-file", "--", "file_to_check.jl"])
```

## Available rules

| Rule ID | Description |
|------|-------------|
|`avoid-containers-with-abstract-types`|Avoid containers with abstract types|
|`avoid-extraneous-whitespace-between-open-and-close-characters`|Avoid extraneous whitespace inside parentheses, square brackets or braces|
|`avoid-global-variables`|Avoid global variables when possible|
|`avoid-hard-coded-numbers`|Avoid hard-coded numbers|
|`avoid-resizing-arrays-and-vectors-after-initialization`|Avoid resizing arrays and vectors after initialization|
|`consistent-line-endings`|Make sure that the line endings are consistent within a file|
|`do-not-change-generated-indices`|Do not change generated indices|
|`do-not-comment-out-code`|Do not comment out code|
|`do-not-nest-multiline-comments`|Don't nest multiline comments|
|`do-not-set-variables-to-inf`|Do not set variables to Inf, Inf16, Inf32 or Inf64|
|`do-not-set-variables-to-nan`|Do not set variables to NaN, NaN16, NaN32 or NaN64|
|`document-constants`|Constants must have a docstring|
|`exclamation-mark-in-function-identifier-if-mutating`|Only functions postfixed with an exclamation mark can mutate an argument|
|`function-arguments-lower-snake-case`|Function arguments must be written in "lower_snake_case"|
|`function-identifiers-in-lower-snake-case`|Function name should be written in "lower_snake_case"|
|`functions-mutate-only-zero-or-one-arguments`|Functions should change only one or zero argument(s)|
|`global-non-const-variables-should-have-type-annotations`|Global non-const variables should have type annotations|
|`global-variables-upper-snake-case`|Casing of globals|
|`implement-unions-as-consts`|Implement Unions as const|
|`indentation-levels-are-four-spaces`|Indentation should be a multiple of four spaces|
|`indentation-of-modules`|Do not indent top level module body, do indent submodules|
|`infinite-while-loop`|Do not use while true|
|`leading-and-trailing-digits`|Floating-point numbers should always have one digit before the decimal point and at least one after|
|`location-of-global-variables`|Global variables should be placed at the top of a module or file|
|`long-form-functions-have-a-terminating-return-statement`|Long form functions should end with an explicit return statement|
|`module-end-comment`|The end statement of a module should have a comment with the module name|
|`module-export-location`|Exports should be implemented after the include instructions|
|`module-import-location`|Packages should be imported after the module keyword|
|`module-include-location`|The list of included files should be after the list of imported packages|
|`module-name-casing`|Package names and module names should be written in UpperCamelCase|
|`module-single-import-line`|The list of packages should be in alphabetical order|
|`multiline-comments-for-many-lines`|Use multiline comments for large blocks|
|`nesting-of-conditional-statements`|Avoid deep nesting of conditional statements|
|`newline-at-file-end`|Single newline at the end of file|
|`no-whitespace-around-type-operators`|Do not add whitespace around type operators|
|`omit-trailing-white-space`|Omit spaces at the end of a line|
|`one-expression-per-line`|The number of expressions per line is limited to one|
|`prefer-const-variables-over-non-const-global-variables`|Prefer const variables over non-const global variables|
|`prefix-of-abstract-type-names`|Abstract type names should be prefixed by "Abstract"|
|`short-hand-function-too-complicated`|Short-hand notation with concise functions|
|`single-module-file`|Single module per file|
|`single-space-after-commas-and-semicolons`|Commas and semicolons are followed, but not preceded, by a space|
|`space-around-binary-infix-operators`|Selected binary infix operators and the = character are followed and preceded by a single space|
|`struct-members-are-in-lower-snake-case`|Struct members should be in "lower_snake_case"|
|`too-many-types-in-unions`|Too many types in Unions|
|`type-names-upper-camel-case`|Type names should be in "UpperCamelCase"|
|`underscore-prefix-for-private-functions`|Private functions are prefixed with one underscore _ character|
|`use-american-english`|Comments should be in the American-English language|
|`use-eachindex-to-iterate-indices`|Use eachindex() instead of a constructed range for iteration over a collection|
|`use-isinf-to-check-for-infinite`|Use isinf to check for infinite values|
|`use-ismissing-to-check-for-missing-values`|Use ismissing to check for missing values|
|`use-isnan-to-check-for-nan`|Use isnan to check for not-a-number values|
|`use-isnothing-to-check-for-nothing-values`|Use isnothing to check variables for nothing|
|`use-spaces-instead-of-tabs`|Use spaces instead of tabs for indentation|
|`variables-have-fixed-types`|Types of variables should not change|
