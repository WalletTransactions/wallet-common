## ADDED Requirements

### Requirement: Base64URL без заполнения
`b64::encode` SHALL кодировать байты или строку в base64url (RFC 4648 §5) без
`=`; `b64::decode` SHALL декодировать обратно и бросать `std::invalid_argument`
при недопустимом символе или длине.

#### Scenario: Круговой проход
- **WHEN** байты закодированы `b64::encode` и переданы в `b64::decode`
- **THEN** получены те же байты

#### Scenario: Недопустимый символ
- **WHEN** в `b64::decode` передана строка с символом вне алфавита base64url
- **THEN** брошено `std::invalid_argument`

### Requirement: Криптопримитивы
`crypto::sha256` SHALL возвращать 32 байта хеша; `crypto::random_bytes(n)` —
`n` байт из `RAND_bytes` и бросать `std::runtime_error`, если энтропии не
хватило; `crypto::constant_time_equal` — сравнивать байтовые массивы за
постоянное время; `crypto::rsa_sha256_verify` — проверять подпись
RSASSA-PKCS1-v1_5 SHA-256 по сырым модулю и экспоненте, возвращая `false` при
любой ошибке и не бросая исключений.

#### Scenario: Битый ключ
- **WHEN** в `rsa_sha256_verify` переданы пустые модуль и экспонента
- **THEN** результат `false`, исключения нет

#### Scenario: Нет энтропии
- **WHEN** ОС не смогла отдать нужное число случайных байт
- **THEN** `random_bytes` бросает `std::runtime_error`, а не возвращает слабые данные

### Requirement: Ключ подписи access-токенов
`crypto::RsaSigningKey(pem_path)` SHALL загружать RSA-ключ из PEM и бросать
`std::runtime_error`, если файла нет, формат битый или ключ не RSA. Объект не
копируется. `modulus()` и `exponent()` отдают только публичную часть, `kid()` —
стабильный идентификатор, выведенный из sha256 DER публичной части ключа.

#### Scenario: Файла нет
- **WHEN** конструктору передан путь к несуществующему файлу
- **THEN** брошено `std::runtime_error`

#### Scenario: Совпадение kid
- **WHEN** ключ загружен дважды из одного PEM
- **THEN** `kid()` у обоих объектов одинаков

### Requirement: Подпись JWT RS256
`jwt::sign_rs256(payload, key)` SHALL возвращать JWS Compact Serialization с
алгоритмом RS256, где заголовок содержит `kid` из `key.kid()`.

#### Scenario: Заголовок с kid
- **WHEN** подписан payload ключом с `kid()` равным `abc`
- **THEN** первая часть токена после декодирования содержит `kid: "abc"`

### Requirement: Проверка JWT RS256
`jwt::verify_rs256(token, n, e, &error)` SHALL проверять подпись по сырым
модулю и экспоненте и срок действия и возвращать payload; иначе `std::nullopt` и
причину в `*error`, если указатель передан: `VerifyError::Malformed` (не три
части, битый base64url или JSON), `BadSignature` (подпись не сошлась), `Expired`
(`exp` нет, он не число или уже наступил). Поле `exp` обязательно. Остальные
claims функция не проверяет.

#### Scenario: Токен без exp
- **WHEN** проверяется токен с верной подписью, но без `exp`
- **THEN** результат `nullopt`, `*error == VerifyError::Expired`

#### Scenario: Просроченный токен
- **WHEN** `exp` в прошлом
- **THEN** результат `nullopt`, `*error == VerifyError::Expired`

#### Scenario: Два сегмента
- **WHEN** передана строка из двух частей через точку
- **THEN** результат `nullopt`, `*error == VerifyError::Malformed`

#### Scenario: Чужая подпись
- **WHEN** токен подписан другим ключом
- **THEN** результат `nullopt`, `*error == VerifyError::BadSignature`

### Requirement: Чтение kid без проверки
`jwt::peek_kid(token)` SHALL возвращать `kid` из заголовка без проверки подписи
или `std::nullopt`, если прочитать его нельзя.

#### Scenario: Нет kid
- **WHEN** в заголовке токена нет `kid`
- **THEN** результат `nullopt`

### Requirement: Кэш публичных ключей JWKS
`jwks::Cache(auth_service_url)` SHALL хранить в памяти публичные ключи
(`n`, `e`) из `GET /.well-known/jwks.json` auth-сервиса и не хранить секретов.
`find(kid)` возвращает ключ из кэша; если его нет, один раз обновляет JWKS и
повторяет поиск; потокобезопасен. `std::nullopt` — ключа нет и после обновления
(auth-сервис недоступен или `kid` неизвестен).

#### Scenario: Ротация ключа
- **WHEN** токен подписан новым `kid`, которого нет в кэше, а JWKS уже его отдаёт
- **THEN** `find` обновляет кэш и возвращает ключ

#### Scenario: Auth недоступен
- **WHEN** `kid` неизвестен кэшу и обновление JWKS не удалось
- **THEN** `find` возвращает `nullopt`

### Requirement: Проверка claims токена
`jwt_claims::check(payload, audience, required_scope)` SHALL проверять издателя
`kIssuer = "google-auth"`, `aud` (имя сервиса) и, если `required_scope` не пуст,
наличие scope, и возвращать одно из `Result::Ok`, `Legacy` (нет `aud`),
`WrongIssuer`, `WrongAudience`, `InsufficientScope`. `has_scope(payload, scope)`
ищет scope в строке `scope` через пробел; `to_string(Result)` даёт `"ok"`,
`"legacy"`, `"wrong_issuer"` и т. д. для логов и метрик.

#### Scenario: Токен старого формата
- **WHEN** в payload нет `aud`
- **THEN** результат `Result::Legacy`

#### Scenario: Чужая аудитория
- **WHEN** `aud` равен `wallet-api`, а проверяет `wallet-report`
- **THEN** результат `Result::WrongAudience`

#### Scenario: Scope не требуется
- **WHEN** `required_scope` пуст, `iss` и `aud` верны
- **THEN** результат `Result::Ok` независимо от поля `scope`

#### Scenario: Нет нужного scope
- **WHEN** требуется `mcp:read`, а в `scope` только `sync`
- **THEN** результат `Result::InsufficientScope`
