#!/usr/bin/env bash
function input() {
	echo "::   input  : $#"
	if [[ "$#" -gt 0 ]]; then
		echo "::   $1";
	elif test ! -t 0; then
		echo "::   /dev/stdin"
		cat
	else
		echo "::   No standard input."
	fi
}
echo ":: stream"
ls -1 | input
echo ":: blank"
input ''
echo ":: 1 option"
input "Hello"
echo ":: nothing"
input
