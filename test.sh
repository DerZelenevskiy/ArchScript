#!/usr/bin/env bash

test1() {
echo
echo "=== TEST 1: заполнение ниже порога ==="
echo "Подготовка: 4 файла по 160M (640M, 62.5%), порог 90%, lzma off"
echo "Ожидание:   архивация не нужна"
echo


unshare -r -m bash -c '
trap "umount /tmp/lab-test/log; rm -rf /tmp/lab-test" EXIT

mkdir -p /tmp/lab-test/log
mkdir -p /tmp/lab-test/backup

mount -t tmpfs -o size=1G disk /tmp/lab-test/log

for i in {1..4}; do
fallocate -l 160M "/tmp/lab-test/log/file$i"
done

bash "$HOME/lab/arch.sh" -c 90 /tmp/lab-test/log /tmp/lab-test/backup

code=$?

echo "exit code: $code"
echo "Содержимое в папке backup:"
ls /tmp/lab-test/backup
echo "Содержимое в папке log:"
ls /tmp/lab-test/log

echo
backup_count=$(ls /tmp/lab-test/backup | wc -l)
log_count=$(ls /tmp/lab-test/log | wc -l)

if [ "$code" -eq 0 ] && [ "$backup_count" -eq 0 ] && [ "$log_count" -eq 4 ]; then
    echo "PASSED"
else
    echo "FAILED"
fi

echo "================================="
echo
'
}

test1
