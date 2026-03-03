# /audit — J.A.R.V.I.S. Integrity Check

Проверка соблюдения "Красных Линий" и стабильности сборки.

## Usage
`/audit [scope]`
Scopes: `build`, `ui`, `core`, `rules`.

## Instructions
1. **Scope: rules** — Проверить отсутствие кириллицы в путях активной сборки.
2. **Scope: build** — Запустить `flutter build apk --dry-run` или проверить конфиги Gradle.
3. **Scope: ui** — Проверить файлы стилей на наличие "hardcoded" цветов вне дизайн-системы.
4. **Scope: core** — Проверить наличие `MainActor` или потокобезопасности в критических сервисах.

Вывести результат в виде таблицы PASS/FAIL.
