## ADDED Requirements

### Requirement: Единственный источник кода
Код `util/`, `expense/` и `clients/` SHALL правиться только в репозитории
wallet-common; копии в `<сервис>/third_party/wallet-common/` руками не правятся.

#### Scenario: Правка нужна сервису
- **WHEN** сервису нужно изменить общий файл
- **THEN** изменение вносится в wallet-common, затем раздаётся `scripts/vendor.sh`, а не правится в копии

### Requirement: Раздача копий
`bash scripts/vendor.sh [путь…]` SHALL заменять в каждой целевой папке
`third_party/wallet-common/{util,expense,clients}` содержимым одноимённых папок
репозитория и записывать рядом файл `VENDORED` с версией из `VERSION` и выводом
`git describe --tags --always --dirty --abbrev=8` (или `unknown`). Без аргументов
целями становятся соседние с wallet-common папки, где уже есть
`third_party/wallet-common/`. Для каждой цели скрипт печатает `vendored <имя> <- <версия> (<коммит>)`.

#### Scenario: Раздача по всем соседям
- **WHEN** запущен `bash scripts/vendor.sh` без аргументов
- **THEN** копии обновлены во всех соседних сервисах с `third_party/wallet-common/`, у каждого — свежий `VENDORED`

#### Scenario: Новый сервис
- **WHEN** запущен `bash scripts/vendor.sh ../wallet-ai` для папки без `third_party/wallet-common/`
- **THEN** папка создаётся и заполняется, как у остальных

#### Scenario: Нет целей
- **WHEN** запущен без аргументов, и ни у одного соседа нет `third_party/wallet-common/`
- **THEN** сообщение «нет сервисов с third_party/wallet-common — укажите путь явно» в stderr и код выхода 2

### Requirement: Сверка копий
`bash scripts/vendor.sh --check [путь…]` SHALL ничего не менять, сравнивать
`util/`, `expense/` и `clients/` с копиями рекурсивно и для каждой цели печатать
`ok <имя>` или `differs <имя>`; при любом расхождении код выхода — 1.

#### Scenario: Копии совпадают
- **WHEN** все копии идентичны источнику
- **THEN** для каждого сервиса напечатано `ok <имя>`, код выхода 0

#### Scenario: Копию поправили руками
- **WHEN** в копии сервиса изменён файл
- **THEN** для сервиса напечатано `differs <имя>`, код выхода 1

### Requirement: Версия библиотеки
Файл `VERSION` SHALL содержать номер версии wallet-common; несовместимое
изменение API поднимает минорную версию, а версия раздачи видна в `VENDORED`
сервиса.

#### Scenario: Какая версия у сервиса
- **WHEN** нужно узнать, какая версия wallet-common лежит в сервисе
- **THEN** она указана в первой строке `third_party/wallet-common/VENDORED`
