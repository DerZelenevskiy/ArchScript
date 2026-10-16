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
test2() {
echo "=== Тест 2: порог передан неверно, директории не переданы ==="
echo "Ожидание:   неверный ввод"
echo
unshare -r -m bash -c '

trap "umount /tmp/lab-test/log; rm -rf /tmp/lab-test" EXIT
mkdir -p /tmp/lab-test/log
mkdir -p /tmp/lab-test/backup

mount -t tmpfs -o size=1G disk /tmp/lab-test/log

bash "$HOME/lab/arch.sh" -c 120
code=$?
echo "exit code: $code"
if [ "$code" -eq 1 ]; then
echo "PASSED"
else
echo "FAILED"
fi
echo "=========================="
'
}
test2
test4() {
echo "=== Тест 4: lzma on, заполнение выше порога, порог в формате долей, директории не передаются ==="
echo "Подготовка: 6 файлов по 150M (900M, 90%), порог 65.5%, lzma on"
echo "Ожидание:   архив создан в формате .tar.xz"
echo

unshare -r -m bash -c '
trap "umount /tmp/lab-test/log; rm -rf /tmp/lab-test" EXIT

mkdir -p /tmp/lab-test/log
mkdir -p /tmp/lab-test/backup

mount -t tmpfs -o size=1G disk /tmp/lab-test/log

for i in {1..6}; do
fallocate -l 150M "/tmp/lab-test/log/file$i"
done
cd /tmp/lab-test/log
export LAB1_MAX_COMPRESSION=1
bash "$HOME/lab/arch.sh" -c 0.655
code=$?
cd - >/dev/null
echo "exit code: $code"

echo "Содержимое в папке backup:"
ls /tmp/lab-test/backup
echo "Содержимое в папке log:"
ls /tmp/lab-test/log
echo "=========================="
echo

log_count=$(ls /tmp/lab-test/log | wc -l)
backup_count=$(ls /tmp/lab-test/backup/*.tar.xz 2>/dev/null | wc -l)


if [ "$code" -eq 0 ] && [ "$log_count" -eq 4 ] && [ "$backup_count" -eq 1 ]; then
echo "Результат: PASS"
else
echo "Результат: FAIL"
fi
'
}
test4
