# /status — J.A.R.V.I.S. State Report

Быстрый аудит текущего состояния проекта и готовности агентов.

## Usage
`/status`

## Instructions
1. Прочитать `agent/CURRENT_FOCUS.md`.
2. Прочитать последние 3 записи из `agent/DECISIONS.md`.
3. Проверить `Worktodo.md` на наличие критических задач.
4. Вывести отчет в формате:

```
═══════════════════════════════════════
J.A.R.V.I.S. — Command Center Status
═══════════════════════════════════════
📌 Current Focus: <from CURRENT_FOCUS.md>
🔜 Next: <from Worktodo.md>

🛡️ Critical Rules Check: <OK/Warning>
🚀 Android Build: <Last known status: Success/Fail>
🎨 UI State: <Standard/Custom Glassmorphism>

📋 Recent Decisions:
1. <from DECISIONS.md>
2. ...

❓ Recommended Action: <based on priority>
═══════════════════════════════════════
```
