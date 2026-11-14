# Proposal: долговые кошельки не для трат

## Why

Часть набора `debts` (issue
[.github-private#10](https://github.com/WalletTransactions/.github-private/issues/10);
парные changes: `wallet-api`, `wallet-report`, `wallet-telegram`,
`android-wallet`). Долг — кошелёк контрагента с признаком `account_debt`;
`GET /api/reports/accounts` wallet-report отдаёт у него `counterparty_uuid`.
Справочник счетов для трат разбирает `resolver::parse_accounts`, и его
используют бот (wallet-telegram), черновики трат ИИ (wallet-ai) и wallet-mcp.
Трата с долгового кошелька — это возврат долга, а не расход: ни бот, ни ИИ
этого не умеют, поэтому такой кошелёк не должен предлагаться.

Фильтр только в боте (как предполагал design wallet-telegram) не закрыл бы
черновики wallet-ai: он сам запрашивает `/accounts` и разбирает тем же
`parse_accounts` (решение владельца 2026-11-12 — править здесь).

## What Changes

- `parse_accounts` отбрасывает кошельки с `counterparty_uuid` не `null`, как
  уже отбрасывает системные категории. Поля нет (wallet-report до `debts`) —
  кошелёк обычный.
- `VERSION` 0.1.1 (API не меняется, поведение — да); раскладка по всем
  сервисам `scripts/vendor.sh`.

## Capabilities

### Modified Capabilities

- `expense-parsing`: справочник счетов без долговых кошельков.

## Impact

- **Код:** `expense/resolver.cpp`, комментарии `expense/resolver.hpp`.
- **Сервисы:** новая копия во всех потребителях; меняется поведение у
  wallet-telegram, wallet-ai, wallet-mcp (используют `parse_accounts`), у
  остальных — только копия.
- **Порядок выката:** безопасен в любом порядке — без поля в ответе ничего не
  отбрасывается.
