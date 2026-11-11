# reports-client Specification

## Purpose
Клиент wallet-report с токеном пользователя для бота и wallet-ai.

## Requirements

### Requirement: Клиент wallet-report
`reports::make_http_api(base_url, error_metric)` SHALL создавать `ReportsApi`,
у которого `get(path_and_query, access_token)` выполняет `GET` на wallet-report
по внутренней сети с заголовком `Authorization: Bearer <access_token>`
пользователя и возвращает `Response`. При ошибке счётчик `error_metric` с
лейблом `kind` увеличивается: `network` или `http_<код>`. Имя метрики задаёт
каждый сервис сам (бот — `tg_reports_errors_total`).

#### Scenario: Ошибка сети
- **WHEN** wallet-report недоступен
- **THEN** счётчик `error_metric{kind="network"}` увеличен

#### Scenario: Ответ 404
- **WHEN** wallet-report отвечает 404
- **THEN** счётчик `error_metric{kind="http_404"}` увеличен

### Requirement: Экранирование query
`reports::url_encode(value)` SHALL выполнять percent-encoding значения
query-параметра по RFC 3986, оставляя нетронутыми unreserved-символы.
Значения query в `path_and_query` вызывающий экранирует сам.

#### Scenario: Пробел и кириллица
- **WHEN** `url_encode("кофе дом")`
- **THEN** результат — `%D0%BA%D0%BE%D1%84%D0%B5%20%D0%B4%D0%BE%D0%BC`
