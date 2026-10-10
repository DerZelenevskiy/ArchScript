#!/bin/zsh

helpSheet="$(basename "$0"): Script for automatic capacity check and archiving outdated files\nUsage:\n $(basename "$0") [-c cap] [path]\nWhere:\n -c: maximal capacity (default: 70%)\n path: path to the working dir (default: pwd)\nUses gzip compression by default\nTo set compression mode to lzma2, set export variable LAB1_MAX_COMPRESSION=1"

#Определение предела заполнения, валидация флагов
maxCapacity=.7
while getopts ":c:h" option; do
  case $option in
  c)
    maxCapacity="${OPTARG%%%}"
#    if [[ ! "$maxCapacity" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then echo "Invalid -$option format"; echo "Use -h for more info"; exit 1; fi
    if (( maxCapacity > 100 )) then echo "Invalid -$option value"; echo "Use -h for more info"; exit 1; fi
    if (( maxCapacity > 1 )) then maxCapacity=$(echo "scale=3; $maxCapacity/100" | bc); fi;;
  h)
    echo "$helpSheet"; exit 0 ;;
  \?)
    echo "Invalid option -$OPTARG"; echo "Use -h for more info"; exit 1 ;;
  :)
    echo "Option -$OPTARG requires an argument"; echo "Use -h for more info"; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

#Определение рабочей директории
dir="$1"
if [[ ! -d "$dir" ]]; then
  if [[ -z "$dir" ]]; then dir="$(pwd)"
  else echo "Invalid path $dir"; echo "Use -h for more info"; exit 1; fi
fi

exit 0