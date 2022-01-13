<?php

$supported_operators = ['+', '-', '*', '/'];

$left = 0;
$operator = '+';

for ($i = 1; $i < $argc; ++$i) {
    if (is_numeric($argv[$i])) {
        if ($operator) {
            $left = eval("return $left $operator {$argv[$i]};");
        }
        $operator = null;
        continue;
    }
    if (in_array($argv[$i], $supported_operators)) {
        $operator = $argv[$i];
    }
}

echo $left;
