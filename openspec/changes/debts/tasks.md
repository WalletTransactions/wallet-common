# Tasks

## 1. Код

- [x] 1.1 `parse_accounts`: кошелёк с `counterparty_uuid` не `null` отбрасывается; поля нет или `null` — оставлен. Проверка: юнит-тест разбора в wallet-telegram (`tests/test_resolver.cpp` — таблица тестов общего кода) зелёный.
- [x] 1.2 `VERSION` 0.1.1, `scripts/vendor.sh` во все сервисы. Проверка: `vendor.sh --check` — все копии `ok`.

## 2. Сервисы

- [ ] 2.1 Копия закоммичена в каждом сервисе (ветки `openspec-debts`), тесты затронутых сервисов (wallet-telegram, wallet-ai, wallet-mcp) зелёные. Проверка: `ctest` в каждом.

## Workflow follow-up

- Архивировать change после выката на test сервисов с новой копией (`openspec archive`).
