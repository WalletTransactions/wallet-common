# Tasks

## 1. Код

- [x] 1.1 `parse_accounts`: кошелёк с `counterparty_uuid` не `null` отбрасывается; поля нет или `null` — оставлен. Проверка: юнит-тест разбора в wallet-telegram (`tests/test_resolver.cpp` — таблица тестов общего кода) зелёный.
- [x] 1.2 `VERSION` 0.1.1, `scripts/vendor.sh` во все сервисы. Проверка: `vendor.sh --check` — все копии `ok`.

## 2. Сервисы

- [x] 2.1 Копия закоммичена в каждом сервисе (ветки `openspec-debts`), тесты затронутых сервисов (wallet-telegram, wallet-ai, wallet-mcp) зелёные. Проверка: `ctest` в каждом.

## Примечания к выполнению

- 1.2, 2.1 — `vendor.sh` разложил 0.1.1 (3549f6e4) в google-auth, wallet-ai, wallet-gateway, wallet-mcp, wallet-api, wallet-report, wallet-telegram, `--check` — все `ok`; копия закоммичена в ветку `openspec-debts` каждого. `resolver.cpp` компилируют wallet-telegram, wallet-ai, wallet-mcp — их `ctest` зелёный (wallet-ai — с `poppler-utils`, как в его Containerfile); остальные получают только копию.
- wallet-mcp: долговые кошельки пропадают и из `list_wallets`/`balance` и сопоставления имени кошелька в фильтрах операций — то же правило; форматирование строк `kind = "debt"` в MCP (сейчас без `from`/`to`) — вне этого change.

## Workflow follow-up

- Архивировать change после выката на test сервисов с новой копией (`openspec archive`).
