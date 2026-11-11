## ADDED Requirements

### Requirement: Формат JSON-логов
Модуль `applog` SHALL писать одну JSON-строку на запись с полями `ts` (UTC,
ISO-8601 с миллисекундами), `level` (`error`/`warn`/`info`/`debug`), `service`
и `msg`; `trace_id` есть только пока он выставлен для потока. Перегрузки с
`details` добавляют поля из JSON-объекта (не объект — игнорируется), но
системные поля `ts`, `level`, `service`, `trace_id`, `msg` перетирают
одноимённые ключи из `details`.

#### Scenario: Запись без trace-id
- **WHEN** вызван `applog::info("listening")` до первого запроса
- **THEN** в строке есть `ts`, `level: "info"`, `service`, `msg`, а поля `trace_id` нет

#### Scenario: Подделка системного поля
- **WHEN** `details` содержит ключ `level` со значением `"debug"`, а вызван `applog::error`
- **THEN** в строке `level` равен `"error"`

### Requirement: Куда пишутся логи
`applog::init(dir, service_name)` SHALL вызываться один раз при старте. Пустой
`dir` — вывод в stdout/stderr; иначе запись в `<dir>/<YYYY-MM-DD>-<service_name>.log`
(дата локальная, папка создаётся), с переходом на новый файл при смене календарной
даты, старые файлы не удаляются.

#### Scenario: Контейнер
- **WHEN** `dir` пуст
- **THEN** файлы не создаются, строки уходят в потоки вывода процесса

### Requirement: Минимальный уровень логов
Переменная окружения `LOG_LEVEL` (`error`, `warn`, `info`, `debug`) SHALL
читаться один раз при первой записи; строки ниже заданного уровня не пишутся.
Не задана или не распознана — пишется всё (как `debug`).

#### Scenario: LOG_LEVEL=warn
- **WHEN** задан `LOG_LEVEL=warn`
- **THEN** `info` и `debug` не пишутся, `warn` и `error` пишутся

### Requirement: Контекст запроса в потоке
`set_trace_id`, `set_route`, `set_user`, `start_request_timer` SHALL хранить
значения в `thread_local`; `current_trace_id`, `current_route`,
`current_user_id`, `request_duration_ms` отдают их, `clear_request_context`
сбрасывает всё. `new_trace_id()` возвращает 32 hex-символа без разделителей и
порождается только на входе в стек (wallet-gateway).

#### Scenario: Поток переиспользован
- **WHEN** запрос завершён вызовом `clear_request_context`, и тот же поток берёт следующий запрос
- **THEN** `current_trace_id()` и `current_route()` пусты, пока новый запрос их не выставит

### Requirement: Метрики HTTP
`metrics::observe_http_request(method, route, status, duration_ms)` SHALL
увеличивать счётчик запросов и гистограмму длительности; `route` — паттерн
маршрута (`applog::current_route()`), а не реальный путь с идентификаторами.
`metrics::render()` SHALL возвращать тело `GET /metrics` в текстовом формате
Prometheus 0.0.4, потокобезопасно.

#### Scenario: Запрос с идентификатором
- **WHEN** обработан `DELETE /api/wallets/<uuid>` с маршрутом `DELETE /api/wallets/:id`
- **THEN** в метриках ряд помечен маршрутом `DELETE /api/wallets/:id`, а не конкретным uuid

### Requirement: Прикладные метрики
`inc_counter(name, help, label, label_value)`, `observe_duration(name, help,
label, label_value)` и `set_gauge(name, help, value)` SHALL заводить
счётчик с одним лейблом, гистограмму длительности с теми же бакетами, что у
HTTP-запросов, и gauge без лейблов; значение лейбла передаётся только литералом
из кода, чтобы кардинальность оставалась ограниченной.

#### Scenario: Счётчик claims
- **WHEN** вызван `inc_counter("jwt_claims_total", help, "result", "legacy")`
- **THEN** `render()` содержит ряд `jwt_claims_total{result="legacy"}`

### Requirement: Информация о сборке
`metrics::set_build_info(service, version, build, git_commit)` SHALL вызываться
один раз в `main()` до `listen()`; `render()` первой строкой отдаёт `build_info`
и `process_start_time_seconds`, а `started_at_iso()` — момент вызова в
ISO-8601 UTC (`2026-11-03T19:24:28Z`). Если вызова не было, блока `build_info`
нет, а `started_at_iso()` пуста.

#### Scenario: Версия выката
- **WHEN** вызван `set_build_info("wallet-api", "0.1.1", "0.1.1-rc.2", …)`
- **THEN** `render()` начинается с `build_info`, а `started_at_iso()` непуста

#### Scenario: Юнит-тест без set_build_info
- **WHEN** `set_build_info` не вызывался
- **THEN** в выводе `render()` нет `build_info`, а `started_at_iso()` возвращает пустую строку
