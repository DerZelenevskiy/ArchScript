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

bash "$HOME/ArchScript/arch.sh" -c 90 /tmp/lab-test/log /tmp/lab-test/backup

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

bash "$HOME/ArchScript/arch.sh" -c 120
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
test3() {
echo "=== Тест 3: порог не передаётся, директории не существует ==="
echo "Ожидание:   неверный ввод"
echo
unshare -r -m bash -c '

trap "umount /tmp/lab-test/log; rm -rf /tmp/lab-test" EXIT
mkdir -p /tmp/lab-test/log
mkdir -p /tmp/lab-test/backup

mount -t tmpfs -o size=1G disk /tmp/lab-test/log

bash "$HOME/ArchScript/arch.sh" /tmp/no-such-dir-xyz
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
test3
test4() {
echo "=== Тест 4: lzma on, заполнение выше порога, порог в формате долей, директории не передаются ==="
echo "Подготовка: 6 файлов по 150M (900M, 87.8%), порог 65.5%, lzma on"
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
bash "$HOME/ArchScript/arch.sh" -c 0.655
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
echo "PASSED"
else
echo "FAILED"
fi
'
}
test4


test5() {
echo
echo "=== TEST 5: lzma off, заполнение выше порога, порог не передаётся, директории передаются ==="
echo "Подготовка: 5 файлов по 160MB (800 MB, 78%), порог 70 (дефолтный)%, lzma off"
echo "Ожидание:   exit 0, один архив в backup, что-то удалено из log"
echo


unshare -r -m bash -c '
trap "umount /tmp/lab-test/log; rm -rf /tmp/lab-test" EXIT

mkdir -p /tmp/lab-test/log
mkdir -p /tmp/lab-test/backup

mount -t tmpfs -o size=1G disk /tmp/lab-test/log

for i in {1..5}; do
fallocate -l 160M "/tmp/lab-test/log/file$i"
touch -d "$((6 - i)) days ago" "/tmp/lab-test/log/file$i"
done

bash "$HOME/ArchScript/arch.sh" /tmp/lab-test/log /tmp/lab-test/backup

code=$?

echo "exit code: $code"
echo "Содержимое в папке backup:"
ls /tmp/lab-test/backup
echo "Содержимое в папке log:"
ls /tmp/lab-test/log

echo
backup_count=$(ls /tmp/lab-test/backup/*.tar.gz | wc -l)
log_count=$(ls /tmp/lab-test/log | wc -l)

if [ "$code" -eq 0 ] && [ "$backup_count" -eq 1 ] && [ "$log_count" -eq 4 ]; then
    echo "PASSED"
else
    echo "FAILED"
fi

echo "================================="
echo
'
}

test5

test6() {
echo "=== Тест 6: порог не передан ==="
echo "Ожидание:   неверный ввод"
echo

unshare -r -m bash -c '
trap "umount /tmp/lab-test/log 2>/dev/null; rm -rf /tmp/lab-test" EXIT

mkdir -p /tmp/lab-test/log
mkdir -p /tmp/lab-test/backup

mount -t tmpfs -o size=1G disk /tmp/lab-test/log

out=$(bash "$HOME/ArchScript/arch.sh" -c 2>&1)
code=$?
echo "$out"
echo "exit code: $code"
echo "=========================="

if [ "$code" -eq 1 ] && echo "$out" | grep -q "requires an argument"; then
    echo "PASSED"
else
    echo "FAILED"
fi
'
}
test6

test7() {
echo
echo "=== TEST 7: передан порог -c 0 ==="
echo "Подготовка: 5 файлов по 160M (800M, 78%), порог 0, lzma off"
echo "Ожидание:   exit 0, 1 архив, log пуст"
echo


unshare -r -m bash -c '
trap "umount /tmp/lab-test/log; rm -rf /tmp/lab-test" EXIT

mkdir -p /tmp/lab-test/log
mkdir -p /tmp/lab-test/backup

mount -t tmpfs -o size=1G disk /tmp/lab-test/log

for i in {1..5}; do
fallocate -l 160M "/tmp/lab-test/log/file$i"
touch -d "$((6 - i)) days ago" "/tmp/lab-test/log/file$i"
done

bash "$HOME/ArchScript/arch.sh" -c 0 /tmp/lab-test/log /tmp/lab-test/backup

code=$?

echo "exit code: $code"
echo "Содержимое в папке backup:"
ls /tmp/lab-test/backup
echo "Содержимое в папке log:"
ls /tmp/lab-test/log

echo
backup_count=$(ls /tmp/lab-test/backup/*.tar.gz | wc -l)
log_count=$(ls /tmp/lab-test/log | wc -l)

if [ "$code" -eq 0 ] && [ "$backup_count" -eq 1 ] && [ "$log_count" -eq 0 ]; then
    echo "PASSED"
else
    echo "FAILED"
fi

echo "================================="
echo
'
}

test7

test8() {
echo
echo "=== TEST 8: передан порог -c 100 ==="
echo "Подготовка: 5 файлов по 160M (800M, 78%), порог 100, lzma off"
echo "Ожидание:   archivation is unnecessary, exit 0, log не тронут"
echo


unshare -r -m bash -c '
trap "umount /tmp/lab-test/log; rm -rf /tmp/lab-test" EXIT

mkdir -p /tmp/lab-test/log
mkdir -p /tmp/lab-test/backup

mount -t tmpfs -o size=1G disk /tmp/lab-test/log

for i in {1..5}; do
fallocate -l 160M "/tmp/lab-test/log/file$i"
touch -d "$((6 - i)) days ago" "/tmp/lab-test/log/file$i"
done

bash "$HOME/ArchScript/arch.sh" -c 100 /tmp/lab-test/log /tmp/lab-test/backup

code=$?

echo "exit code: $code"
echo "Содержимое в папке backup:"
ls /tmp/lab-test/backup
echo "Содержимое в папке log:"
ls /tmp/lab-test/log

echo
backup_count=$(ls /tmp/lab-test/backup/ | wc -l)
log_count=$(ls /tmp/lab-test/log | wc -l)

if [ "$code" -eq 0 ] && [ "$backup_count" -eq 0 ] && [ "$log_count" -eq 5 ]; then
    echo "PASSED"
else
    echo "FAILED"
fi

echo "================================="
echo
'
}

test8
