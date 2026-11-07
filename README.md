## Шаблон для третьего ДЗ по ИПР

Условие дз доступно по [ссылке](https://github.com/Nikfilk2030/missing_semester_hse_cs/blob/main/2026/amcs/year_1/hw_3/README.md)

## 4 балла — один контейнер

### Сборка образа obraz
```sh
docker build -t obraz ./
```
### Запуск контейнера
```sh
docker run -d --name container -p 8080:8000 -e GREETING="Hello from supersonic" obraz
docker ps
```
```
5f27ca59d509509beb08ed3a4e7548bad33ec31b16b4b94d3ef57e75049a2ed2
CONTAINER ID   IMAGE     COMMAND            CREATED          STATUS         PORTS                                         NAMES
5f27ca59d509   obraz     "python3 app.py"   10 seconds ago   Up 9 seconds   0.0.0.0:8080->8000/tcp, [::]:8080->8000/tcp   container
```
### Проверка счётчика

```sh
curl -fsS http://127.0.0.1:8080/
curl -fsS -X POST http://127.0.0.1:8080/increment
curl -fsS -X POST http://127.0.0.1:8080/increment
curl -fsS -X POST http://127.0.0.1:8080/increment
curl -fsS http://127.0.0.1:8080/
curl -fsS http://127.0.0.1:8080/readyz
```
```
{"greeting": "Hello from supersonic", "count": 0, "hostname": "5f27ca59d509", "storage": "sqlite"}
{"greeting": "Hello from supersonic", "count": 1, "hostname": "5f27ca59d509", "storage": "sqlite"}
{"greeting": "Hello from supersonic", "count": 2, "hostname": "5f27ca59d509", "storage": "sqlite"}
{"greeting": "Hello from supersonic", "count": 3, "hostname": "5f27ca59d509", "storage": "sqlite"}
{"greeting": "Hello from supersonic", "count": 3, "hostname": "5f27ca59d509", "storage": "sqlite"}
{"status": "ready", "storage": "sqlite"}
```
### Логи
```sh
docker logs container
```
```
2026-11-07 19:26:41,186 listening port=8000 storage=sqlite
2026-11-07 19:28:52,855 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-07 19:28:52,865 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
2026-11-07 19:28:52,875 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
2026-11-07 19:28:52,884 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
2026-11-07 19:28:52,893 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-07 19:30:11,334 http 172.17.0.1 "GET /readyz HTTP/1.1" 200 -
```

## 6 баллов — Compose и данные

### Сборка и увеличение счетчика
```sh
docker compose up -d --build
curl -fsS http://127.0.0.1:8080/
curl -fsS -X POST http://127.0.0.1:8080/increment
curl -fsS -X POST http://127.0.0.1:8080/increment
curl -fsS -X POST http://127.0.0.1:8080/increment
curl -fsS http://127.0.0.1:8080/
```
```
{"greeting": "Hello from supersonic", "count": 0, "hostname": "9e596dec2f06", "storage": "sqlite"}
{"greeting": "Hello from supersonic", "count": 1, "hostname": "9e596dec2f06", "storage": "sqlite"}
{"greeting": "Hello from supersonic", "count": 2, "hostname": "9e596dec2f06", "storage": "sqlite"}
{"greeting": "Hello from supersonic", "count": 3, "hostname": "9e596dec2f06", "storage": "sqlite"}
{"greeting": "Hello from supersonic", "count": 3, "hostname": "9e596dec2f06", "storage": "sqlite"}
```
### Удаление и создание нового контейнера, проверка сохранения счетчика
```sh
docker compose down
docker compose up -d
curl -fsS http://127.0.0.1:8080/
```
```
{"greeting": "Hello from supersonic", "count": 3, "hostname": "cb0ad526f525", "storage": "sqlite"}
```
hostname1 = 9e596dec2f06, hostname2 = cb0ad526f525, hostname1 не равен hostname2, а счетчик равен 3 в обоих случаях, значит данные сохранились в volume.