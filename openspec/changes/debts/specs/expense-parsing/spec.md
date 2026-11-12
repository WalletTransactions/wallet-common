# Spec Delta

## MODIFIED Requirements

### Requirement: Справочник счетов
`resolver::parse_accounts(body)` SHALL разбирать ответ `GET /api/reports/accounts`
в `Accounts`, исключая системные категории (Transfer, Transfer commission) и
долговые кошельки (`counterparty_uuid` не `null`; отсутствие поля — кошелёк не
долговой), а `names_for_parser(accounts)` — строить `Names` для `parse_strict`
из имён и валют.

#### Scenario: Системная категория
- **WHEN** в ответе есть категория «Transfer»
- **THEN** она отсутствует в `Accounts`

#### Scenario: Долговой кошелёк
- **WHEN** в ответе есть кошелёк «Вася · USD» с `counterparty_uuid` не `null`
- **THEN** он отсутствует в `Accounts.wallets`, и его имя не попадает в `names_for_parser`

#### Scenario: Ответ без поля counterparty_uuid
- **WHEN** у кошелька нет поля `counterparty_uuid` или оно `null`
- **THEN** кошелёк есть в `Accounts.wallets`
