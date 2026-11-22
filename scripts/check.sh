#!/usr/bin/env bash

PROJECT="check_$$_$RANDOM"
export FREE_PORT=8888
cleanup() {
    if ! docker compose -p "$PROJECT" down -v; then
        echo "Ошибка при удалении тестового проекта"
        exit 1
    fi
}
trap cleanup EXIT
if ! docker compose -p "$PROJECT" up -d --build --wait --wait-timeout 20; then
    echo "Ошибка при запуске"
    exit 1
fi
if ! START=$(curl -fsS --max-time 3 http://127.0.0.1:8888/); then
    echo "Ошибка при получении стартового значения счетчика"
    exit 1
fi
START_COUNT=$(echo "$START" | grep -o '"count": *[0-9]*' | grep -o '[0-9]*')
if (( START_COUNT != 0 )); then
    echo "Стартовое значение счетчика не равно 0"
    exit 1
fi

N=$((RANDOM % 10 + 1))
for ((i=0; i<N; i++)); do
    if ! curl -fsS --max-time 3 -X POST http://127.0.0.1:8888/increment > /dev/null; then
        echo "Ошибка при увеличении счетчика"
        exit 1
    fi
done
if ! NOW=$(curl -fsS --max-time 3 http://127.0.0.1:8888/); then
    echo "Ошибка при получении значения счетчика"
    exit 1
fi
NOW_COUNT=$(echo "$NOW" | grep -o '"count": *[0-9]*' | grep -o '[0-9]*')
if (( NOW_COUNT != N )); then
    echo "Счетчик равен $NOW_COUNT вместо $N"
    exit 1
fi

if ! docker compose -p "$PROJECT" rm -sf app; then
    echo "Ошибка при удалении app"
    exit 1
fi
if ! docker compose -p "$PROJECT" up -d --wait --wait-timeout 20 --no-deps app; then
    echo "Ошибка при перезапуске app"
    exit 1
fi
if ! AFTER_DEL=$(curl -fsS --max-time 3 http://127.0.0.1:8888/); then
    echo "Ошибка при получении значения счетчика"
    exit 1
fi
AFTER_DEL_COUNT=$(echo "$AFTER_DEL" | grep -o '"count": *[0-9]*' | grep -o '[0-9]*')
if (( AFTER_DEL_COUNT != N )); then
    echo "Счетчик равен $AFTER_DEL_COUNT вместо $N"
    exit 1
fi

if ! docker compose -p "$PROJECT" stop redis; then
    echo "Ошибка при остановке Redis"
    exit 1
fi
sleep 5
READY=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://127.0.0.1:8888/readyz)
if (( READY != 503 )); then
    echo "readyz должен вернуть 503"
    exit 1
fi
INCREMENT=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 -X POST http://127.0.0.1:8888/increment)
if (( INCREMENT != 503 )); then
    echo "increment должен вернуть 503"
    exit 1
fi
HEALTH=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://127.0.0.1:8888/healthz)
if (( HEALTH != 200 )); then
    echo "healthz должен вернуть 200"
    exit 1
fi
if ! docker compose -p "$PROJECT" start redis; then
    echo "Ошибка при запуске Redis"
    exit 1
fi
sleep 10
READY=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://127.0.0.1:8888/readyz)
if (( READY != 200 )); then
    echo "Ошибка: приложение не восстановилось после запуска Redis"
    exit 1
fi
if ! AFTER_STOP_REDIS=$(curl -fsS --max-time 3 http://127.0.0.1:8888/); then
    echo "Ошибка при получении счетчика после перезапуска Redis"
    exit 1
fi
AFTER_STOP_REDIS_COUNT=$(echo "$AFTER_STOP_REDIS" | grep -o '"count": *[0-9]*' | grep -o '[0-9]*')
if (( AFTER_STOP_REDIS_COUNT != N )); then
    echo "Счетчик равен $AFTER_STOP_REDIS_COUNT вместо $N"
    exit 1
fi
if ! curl -fsS --max-time 3 -X POST http://127.0.0.1:8888/increment > /dev/null; then
    echo "Ошибка при увеличении счетчика после перезапуска Redis"
    exit 1
fi
if ! AFTER_INCREASE=$(curl -fsS --max-time 3 http://127.0.0.1:8888/); then
    echo "Ошибка при получении счетчика после увеличения"
    exit 1
fi
AFTER_INCREASE_COUNT=$(echo "$AFTER_INCREASE" | grep -o '"count": *[0-9]*' | grep -o '[0-9]*')
if (( AFTER_INCREASE_COUNT != N + 1 )); then
    echo "Счетчик равен $AFTER_INCREASE_COUNT вместо $((N + 1))"
    exit 1
fi

if ! docker compose -p "$PROJECT" stop app redis; then
    echo "Ошибка при остановке контейнеров"
    exit 1
fi
mkdir -p backup
REDIS_ID=$(docker compose -p "$PROJECT" ps -a -q redis)
if ! docker cp -a "$REDIS_ID:/data" - > "backup/redis_$PROJECT.tar"; then
    echo "Ошибка при создании резервной копии"
    exit 1
fi
