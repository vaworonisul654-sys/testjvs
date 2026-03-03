# /save — J.A.R.V.I.S. Session Save

Завершение сессии, обновление логов и синхронизация состояния.

## Usage
`/save [notes]`

## Instructions
1. Проанализировать выполненную работу.
2. Обновить `agent/CURRENT_FOCUS.md`:
   - Перенести выполненное в "Недавно завершено".
   - Обновить "В работе" актуальными задачами.
3. Обновить `Worktodo.md`: пометить выполненные задачи как `FIXED`.
4. Если было архитектурное решение — добавить в `agent/DECISIONS.md`.
5. Обновить `agent/PROGRESS_LOG.md` новой записью.
6. Вывести подтверждение:
`✅ Session Saved | Focus Updated | Decisions Logged: <N> | Tasks Fixed: <N>`
