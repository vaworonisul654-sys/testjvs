# CRITICAL RULES & SACRED CONSTANTS 🚨

## 🔴 Красные Линии (Запрещено)
1.  **Кириллица в путях:** Никогда не запускать `flutter build` или команды компиляции в папках с русскими буквами.
2.  **Удаление данных:** Запрещено удалять файлы без создания снапшота или явного подтверждения.
3.  **API Keys:** Никогда не коммитить секретные ключи напрямую в код. Только `local.properties` (Android) или `.env`.

## ⭐ Священные Константы (Архитектура)
- **minSdkVersion:** 21 (Android)
- **targetSdkVersion:** 34
- **Gradle Version:** 8.7
- **Kotlin Version:** 2.1.0
- **Primary Colors:** `Emerald (#50C878)`, `Dark Blue (#003366)`
- **Framework:** Flutter (Android/iOS), SwiftUI (iOS Native Core)

## 🛡️ Протокол верификации
Любая задача по коду завершается запуском:
`flutter build apk --release`
Если сборка упала — задача не выполнена.
