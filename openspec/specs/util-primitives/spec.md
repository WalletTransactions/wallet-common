# util-primitives Specification

## Purpose
Мелкие общие утилиты серверных сервисов: загрузка .env, UUID v4/v5, hex-кодек.

## Requirements

### Requirement: Загрузка .env
`dotenv::load(path = ".env")` SHALL читать `KEY=VALUE` построчно и класть пары в
окружение процесса, не перезаписывая переменные, уже выставленные в реальном
окружении.

#### Scenario: Переменная уже задана
- **WHEN** в `.env` есть `PORT=8080`, а в окружении уже `PORT=9000`
- **THEN** после `load` значение остаётся `9000`

### Requirement: UUID
`uuidgen::v4()` SHALL возвращать случайный UUID v4; `uuidgen::v5(namespace_uuid,
name)` — детерминированный UUID v5 (SHA-1) и бросать `std::invalid_argument`,
если `namespace_uuid` не в формате 8-4-4-4-12; `uuidgen::looks_valid(s)` —
проверять только формат 8-4-4-4-12 hex.

#### Scenario: Идемпотентность v5
- **WHEN** `v5` вызвана дважды с одним namespace и именем
- **THEN** результаты равны

#### Scenario: Невалидный namespace
- **WHEN** `v5("не-uuid", "x")`
- **THEN** брошено `std::invalid_argument`

### Requirement: Hex-кодек
`hex::encode` SHALL возвращать нижний регистр без разделителей (вдвое длиннее
входа); `hex::decode` — бросать `std::invalid_argument` при нечётной длине или
символе вне `[0-9a-fA-F]`; `hex::looks_like_sha256(s)` — `true` только для
ровно 64 hex-символов и не бросать.

#### Scenario: Нечётная длина
- **WHEN** `hex::decode("abc")`
- **THEN** брошено `std::invalid_argument`

#### Scenario: Проверка хеша
- **WHEN** `looks_like_sha256` получает строку из 63 символов
- **THEN** результат `false`
