#!/bin/bash

helpSheet="$(basename "$0"): Script for automatic capacity check and archiving outdated files
Usage:
  $(basename "$0") [-c cap] [working-dir] [backup-dir]
Where:
 -c: maximal capacity (default: 70%)
  working-dir: path to the working directory (default: pwd)
  backup-dir: path to the destination directory (default ../backup)
Uses gzip compression by default
To set compression mode to lzma2, set export variable LAB1_MAX_COMPRESSION=1"

#Определение предела заполнения, валидация флагов
maxCapacity=.7
while getopts ":c:h" option; do
  case $option in
  c)
    maxCapacity="${OPTARG%%%}"
    if [[ ! "$maxCapacity" =~ ^[0-9]*(\.[0-9]+)?$ ]]; then echo "Invalid -$option format" >&2; echo "Use -h for more info"; exit 1; fi
    if [[ "$(echo "$maxCapacity > 100" | bc)" -eq 1 ]]; then echo "Invalid -$option value" >&2; echo "Use -h for more info"; exit 1; fi
    if [[ "$(echo "$maxCapacity > 1" | bc)" -eq 1 ]]; then maxCapacity="$(echo "scale=3; $maxCapacity/100" | bc)"; fi;;
  h)
    echo "$helpSheet"; exit 0 ;;
  \?)
    echo "Invalid option -$OPTARG" >&2; echo "Use -h for more info"; exit 1 ;;
  :)
    echo "Option -$OPTARG requires an argument" >&2; echo "Use -h for more info"; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

#Определение рабочей директории
logDir="$1"
if [ ! -d "$logDir" ]; then
  if [ -z "$logDir" ]; then logDir="$(pwd)"
  else echo "Invalid working-dir $logDir" >&2; echo "Use -h for more info"; exit 1; fi
fi
logDir="$(realpath "$logDir")"

#Определение директории для сохранения архива
backupDir="$2"
if [ ! -d "$backupDir" ]; then
  if [ -z "$backupDir" ]; then backupDir=$(readlink -f "$logDir/../backup"); if [ ! -d "$backupDir" ]; then mkdir "$backupDir"; fi
  else echo "Invalid backup-dir $backupDir" >&2; echo "Use -h for more info"; exit 1; fi
fi
backupDir="$(realpath "$backupDir")"

#Определение текущего размера папки и объема диска
maxSize="$(df -k --output=size "$logDir" | tail -n 1 | tr -d " ")"
curSize="$(du -sk "$logDir" | cut -f 1)"

#Определение процента заполнения и сравнение с порогом
used="$(echo "scale=3; $curSize / $maxSize" | bc)"
echo "Current use of $logDir: $(echo "scale=1; $used * 100 / 1" | bc)%"
if [[ "$(echo "$used < $maxCapacity" | bc)" -eq 1 ]]; then
  echo "Archivation is unnecessary"
  exit 0
fi
echo "Archiving..."

#Вычисление объема который необходимо освободить
maxSize="$(echo "$maxSize * $maxCapacity" | bc)"
toBeFreed="$(echo "scale=0; $curSize - $maxSize / 1" | bc)"
fileList="$(mktemp)"

#Цикл по отсортированным файлам, добавление их в temp файл
#пока сумма размеров меньше чем $toBeFreed
totalSize=0
fileCount=0
while read -r time size path; do
  if [[ ! "$(basename "$0")" = "$path" ]]; then echo "$path" >> "$fileList"; fi
  (( totalSize += size ))
  (( ++fileCount ))
  if (( totalSize >= toBeFreed )); then break; fi
done < <(cd "$logDir" && find . -type f -printf "%T+ %k %P\n" | sort)

#Проверка наличия файлов
#if (( fileCount == 0 )); then echo "No files to archive"; exit 0; fi
echo "Files found: $fileCount with total size of $((totalSize / 1024))MB"

#Создание архива
if [ "$LAB1_MAX_COMPRESSION" = 1 ]; then
  archName="$backupDir/backup_$(date +"%Y-%m-%d_%H-%M-%S").tar.xz"
  tar -cJf "$archName" --remove-files -C "$logDir" -T "$fileList"
else
  archName="$backupDir/backup_$(date +"%Y-%m-%d_%H-%M-%S").tar.gz"
  tar -czf "$archName" --remove-files -C "$logDir" -T "$fileList"
fi
echo "Archive created: $archName"

#Удаление временного файла
rm -f "$fileList"
exit 0