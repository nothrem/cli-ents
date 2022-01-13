In this folder you can find tools that are not available as commands or tools in Windows. 

Calc.exe
********

Windows Command allows to perform simple mathematics operations but has some limitations - one of the biggest is that it only supports INTEGER values
and cannot work with FLOAT numbers.

Supported:
* positive and negative float numbers ('.' is decimal separator, '_' is optional thousands separator)
* positive and negative binary numbers (must start with 0); result will always be decimal; by passing just one binary number the tool will convert it to decimal
* operators +, -, *, /
* When using command variables in calculation and a variable is empty, its operation will be skipped.
  e.g.
  ```
  set a=10
  set b=
  set c=10
  calc %a% * %b% * %c% 
  //will output 100 (=10 * 10); in other languages 0 would be the result (=10 * 0 * 10)
  ```

Not supported/Known issues
* When operating negative numbers there must be no space between the minus sign and the number (unless it's first number in the command or the operator is +).  
  e.g. `5 + - 10` and `-5 + 10` is OK, but '5 * - 10' will be processed as `5 - 10`

_This tool is written in PHP, compiled using PHC and compressed by EVB (Enigma Virtual Box)._
