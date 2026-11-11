## ADDED Requirements

### Requirement: Строгий формат траты
`parser::parse_strict(text, names, now)` SHALL разбирать сообщение вида
`<сумма> [<валюта>] <категория> [@<кошелёк>] [<дата>] [// <комментарий>]` в
`ParsedExpense` (`amount`, `currency`, категория, кошелёк, дата, комментарий)
без сети, базы и часов. Парсер только режет текст на поля: выбор счетов — у
`resolver`. Без `//` граница между многословной категорией и комментарием
определяется по `names` (самое длинное совпадение).

#### Scenario: Простая трата
- **WHEN** разбирается «350 кофе» с категорией «кофе» в `names`
- **THEN** `amount` = `350`, категория = «кофе», валюта, кошелёк и комментарий пусты

#### Scenario: Многословная категория
- **WHEN** разбирается «1200 такси домой» при категории «такси домой» в `names`
- **THEN** категория = «такси домой», комментария нет

#### Scenario: Явный комментарий
- **WHEN** разбирается «200 кофе // с Колей»
- **THEN** категория = «кофе», комментарий = «с Колей»

### Requirement: Сумма и дата траты
`amount` SHALL быть десятичной строкой с точкой, без ведущих и хвостовых нулей
(`"1200.5"`, `"350"`) и строго больше нуля. Дата — `YYYY-MM-DD HH:MM:SS` без
пояса: для сегодня — текущее время `now.time`, для прошедшего дня — `12:00:00`.

#### Scenario: Запятая в сумме
- **WHEN** разбирается «1200,50 продукты»
- **THEN** `amount` = `1200.5`

#### Scenario: Прошедшая дата
- **WHEN** в сообщении указан вчерашний день
- **THEN** время операции — `12:00:00` этого дня

### Requirement: Причины отказа разбора
При неуспехе `Result` SHALL нести `ParseError::Reason`: `NoAmount` (сообщение не
начинается с суммы), `BadAmount` (`1,200.50`, `350кафе`, больше 12 знаков до или
8 после разделителя), `ZeroAmount` (`0`, `0,00`), `BadDate` (`31.02`, `32.13`),
`FutureDate` (позже сегодняшней). `reason_name(Reason)` SHALL возвращать имя
причины для метрики `tg_parse_fail_total{reason}`.

#### Scenario: Не трата
- **WHEN** разбирается «привет»
- **THEN** `Reason::NoAmount`

#### Scenario: Нулевая сумма
- **WHEN** разбирается «0 кофе»
- **THEN** `Reason::ZeroAmount`

#### Scenario: Несуществующая дата
- **WHEN** разбирается «500 аренда 31.02»
- **THEN** `Reason::BadDate`

### Requirement: Части разбора для проверки ответа LLM
Для проверки ответа модели в wallet-ai SHALL быть доступны те же правила, что
у `parse_strict`: `parse_amount(core, &why)` (число без валюты, `nullopt` и
`why` = `BadAmount`/`ZeroAmount` при неудаче), `amounts_in_text(text, names)`
(все суммы текста, нормализованные как `Amount::amount`: «1 200,50 продукты, $12
и 350₽» → `1200.5`, `12`, `350`), `currency_of(word, names)` (ISO-код по слову,
символу или коду валюты кошелька, иначе пусто), `check_date(ymd, today,
max_age_days)` → `DateCheck::{Ok, Bad, Future, TooOld}` и `datetime_for(ymd, now)`.

#### Scenario: Суммы в тексте
- **WHEN** вызван `amounts_in_text("1 200,50 продукты, $12 и 350₽", names)`
- **THEN** результат — `["1200.5", "12", "350"]`

#### Scenario: Слишком старая дата
- **WHEN** `check_date` получает дату раньше, чем `max_age_days` назад
- **THEN** результат `DateCheck::TooOld`

### Requirement: Разрешение траты в счета
`resolver::resolve(expense, accounts, default_wallet_uuid)` SHALL возвращать
`Resolution` с `CategoryPick` (`Kind::Found` или `Ask`, причины `Missing`,
`NotFound`, `Ambiguous`) и `WalletPick` (`Kind::Found`, `Ask` или `Reject`).
Причины кошелька: `NotGiven`, `NotFound`, `Ambiguous`, `CurrencyMismatch` (Ask),
`NoWalletInCurrency`, `NoWallets` (Reject). Кандидатов показывается не больше
`kMaxCandidates = 6`. Кошелёк по умолчанию, которого нет среди `wallets`,
считается не заданным. Функция чистая.

#### Scenario: Кошелька нет вовсе
- **WHEN** у пользователя нет кошельков
- **THEN** `WalletPick::Kind::Reject`, `Why::NoWallets`

#### Scenario: Неоднозначное имя
- **WHEN** «@карта» подходит к двум кошелькам
- **THEN** `Kind::Ask`, `Why::Ambiguous`, оба кошелька в `candidates`

#### Scenario: Кошелёк по умолчанию удалён
- **WHEN** `default_wallet_uuid` не найден в `wallets`, а «@кошелёк» не указан
- **THEN** кошелёк считается незаданным: `Kind::Ask`, `Why::NotGiven`

### Requirement: Точность суммы
`resolver::fits_precision(expense, wallet)` SHALL возвращать `true`, если знаков
после запятой в сумме не больше `precision` валюты кошелька; округления нет.

#### Scenario: Лишние знаки
- **WHEN** сумма `10.555`, а у кошелька `precision` = 2
- **THEN** `fits_precision` возвращает `false`

### Requirement: Справочник счетов
`resolver::parse_accounts(body)` SHALL разбирать ответ `GET /api/reports/accounts`
в `Accounts`, исключая системные категории (Transfer, Transfer commission), а
`names_for_parser(accounts)` — строить `Names` для `parse_strict` из имён и
валют.

#### Scenario: Системная категория
- **WHEN** в ответе есть категория «Transfer»
- **THEN** она отсутствует в `Accounts`

### Requirement: Чистые функции текста
`text::normalize_name` SHALL приводить имя к нижнему регистру (ASCII и кириллица),
заменять `ё` на `е`, убирать пробелы по краям и схлопывать внутренние.
`text::resolve_name(query, items)` — сначала точное совпадение нормализованных
имён, затем уникальный префикс; несколько префиксных совпадений дают
`Kind::Ambiguous` со всеми кандидатами, ни одного — `NotFound`.
`text::format_amount("12345.6", "2", "₽")` — «12 345,60 ₽» (узкий неразрывный
пробел в разряде, десятичная строка без `double`; пустой символ — без него;
непарсящаяся строка возвращается как есть). `format_day_month` превращает
`2026-09-28T12:00:00`, `2026-09-28 12:00:00` и `2026-09-28` в `28.09`.
`truncate_utf8` обрезает по границе UTF-8 с «…».

#### Scenario: Ё и регистр
- **WHEN** `normalize_name("  ЁЛКА   Базар ")`
- **THEN** результат — «елка базар»

#### Scenario: Префикс неоднозначен
- **WHEN** запрос «кар» подходит к «карта» и «каруселька» и точного совпадения нет
- **THEN** `Kind::Ambiguous` с двумя кандидатами

#### Scenario: Формат суммы
- **WHEN** `format_amount("12345.6", "2", "₽")`
- **THEN** результат «12 345,60 ₽»
