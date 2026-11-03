# wallet-common

Общий C++-код серверных сервисов WalletTransactions: `util/` — JWT/JWKS,
проверка claims, криптография (OpenSSL), JSON-логи, метрики Prometheus,
`.env`, UUID v4/v5, hex, base64. До 2026-10-11 каждый сервис держал свою
копию этих файлов, и копии расходились.

| Файл | Что | Кто использует |
| --- | --- | --- |
| `util/base64` | base64url | google-auth, wallet-api, wallet-report, wallet-gateway, wallet-ai |
| `util/crypto` | SHA-256, `random_bytes`, `constant_time_equal`, `rsa_sha256_verify`, `RsaSigningKey` | те же |
| `util/jwt` | `sign_rs256` (google-auth), `verify_rs256` (подпись + обязательный exp, причина отказа — `VerifyError`), `peek_kid` | те же |
| `util/jwks` | кеш JWKS google-auth | сервисы, проверяющие токены |
| `util/jwt_claims` | проверка `iss`/`aud`/`scope` | все, кто проверяет токены |
| `util/log` | JSON-логи, trace-id, `LOG_LEVEL` | все |
| `util/metrics` | `/metrics`: HTTP-гистограммы, счётчики, гистограммы, gauge; `set_build_info(service, version, build, git_commit)` — `build_info` и `process_start_time_seconds`, `started_at_iso()` для `started_at` в `GET /version` | все |
| `util/dotenv` | загрузка `.env` | все |
| `util/uuid` | v4, v5, проверка формата | wallet-api, wallet-report (тесты), google-auth, wallet-telegram |
| `util/hex` | hex, `looks_like_sha256` | wallet-api, wallet-report (тесты), wallet-telegram |

Кроме `util/` — общий код разбора трат и клиент wallet-report (2026-10-11,
шаг 3 `org/docs/TODO_wallet_ai.md`): строгий формат бота и проверка ответа
LLM в `wallet-ai` должны разбирать суммы и даты одинаково.

| Файл | Что | Кто использует |
| --- | --- | --- |
| `expense/strict` | строгий формат трат (`parse_strict`), `parse_amount`, `amounts_in_text`, `currency_of`, `check_date`, `datetime_for` | wallet-telegram, wallet-ai |
| `expense/resolver` | имена → счета (uuid) или кандидаты для вопроса, `parse_accounts` (ответ `GET /api/reports/accounts`) | wallet-telegram, wallet-ai |
| `expense/text` | `normalize_name` (регистр, ё→е), `resolve_name`, формат сумм и дат, `truncate_utf8` | wallet-telegram, wallet-ai |
| `clients/reports_client` | `GET` в wallet-report токеном пользователя; имя метрики ошибок — параметр | wallet-telegram, wallet-ai |

Тесты `expense/` — в `wallet-telegram/tests/` (`test_strict`, `test_resolver`,
`test_text`) и `wallet-ai/tests/` (`test_expense_check`).

Код, нужный одному сервису (`time`, `url` у google-auth, `tz` у бота), в
общую библиотеку не входит и остаётся в `src/util/` сервиса.

## Как подключено

Не сабмодуль и не пакет: копия лежит в каждом сервисе в
`third_party/wallet-common/` — так же, как `httplib.h` и `nlohmann`. Каждый
репозиторий собирается сам по себе: Containerfile (`COPY third_party/`) и CI
менять не нужно.

В `CMakeLists.txt` сервиса:

```cmake
set(WALLET_COMMON_DIR ${CMAKE_SOURCE_DIR}/third_party/wallet-common)
add_executable(svc ... ${WALLET_COMMON_DIR}/util/log.cpp ...)
target_include_directories(svc PRIVATE ... ${WALLET_COMMON_DIR})
```

Заголовки подключаются как раньше: `#include "util/log.hpp"`.

Зависимости: OpenSSL (`crypto`, `uuid`), `nlohmann/json.hpp` и `httplib.h`
из `third_party/` сервиса (`jwks`).

## Как менять

1. Правка — **только здесь**, не в копии сервиса.
2. `bash wallet-common/scripts/vendor.sh` — разложить `util/`, `expense/`, `clients/` по всем сервисам
   (соседние папки с `third_party/wallet-common/`). Новый сервис — указать
   путь явно: `bash wallet-common/scripts/vendor.sh ../wallet-ai`.
3. Собрать и прогнать тесты затронутых сервисов, закоммитить копию в каждом.
4. `bash wallet-common/scripts/vendor.sh --check` — все копии совпадают с
   источником.

Несовместимые изменения API (как обязательный `exp` в `verify_rs256`)
поднимают минорную версию в `VERSION`; в `third_party/wallet-common/VENDORED`
сервиса видно, какая версия у него лежит.
