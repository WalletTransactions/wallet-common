# Proposal: базовая спецификация wallet-common

## Why

Общий код используют шесть сервисов, а его контракт описан только комментариями
в заголовках и `README.md`. Любая правка `util/` или `expense/` расходится по
сервисам копией, поэтому нужна явная спецификация текущего поведения, к которой
следующие изменения будут идти дельтой.

## What Changes

- Фиксируется **текущее** поведение по заголовкам `util/*.hpp`, `expense/*.hpp`,
  `clients/reports_client.hpp`, `scripts/vendor.sh` и `README.md`.
- Сервисы-потребители описываются только как границы: что им обещает библиотека.
- Код и скрипты **не меняются**.

## Capabilities

### New Capabilities

- `vendoring`: раздача `util/`, `expense/`, `clients/` по сервисам и сверка копий.
- `token-verification`: base64url, SHA-256, RSA-SHA256, JWT RS256, кэш JWKS,
  проверка `iss`/`aud`/`scope`.
- `observability`: JSON-логи, trace-id, метрики Prometheus, `build_info`.
- `expense-parsing`: строгий формат траты, части разбора для проверки ответа LLM,
  разрешение имён в кошелёк и категорию, чистые функции текста.
- `util-primitives`: `.env`, UUID v4/v5, hex.
- `reports-client`: клиент `wallet-report` с токеном пользователя.

## Impact

Нет изменений кода и поведения. Появляется `openspec/` в репозитории.
