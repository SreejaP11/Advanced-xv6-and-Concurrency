#!/bin/bash
program_name=$(basename "$1" .out)

/usr/bin/time -v ./$1 2> ${program_name}_usage.txt

runtime=$(grep -E "User time|System time" ${program_name}_usage.txt | awk '{sum += $4} END {print sum}')
memory=$(grep "Maximum resident set size" ${program_name}_usage.txt | awk '{print $6}')

echo "Total Runtime (seconds): $runtime"
echo "Max Memory Usage (KB): $memory"
