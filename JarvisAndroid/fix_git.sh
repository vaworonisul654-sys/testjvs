#!/bin/bash
echo "--- J.A.R.V.I.S. Git Repair System ---"

# 1. Жесткая очистка от мусора
rm -rf build/
rm -rf .dart_tool/
rm -rf android/.gradle/
rm -rf .idea/

# 2. Создание абсолютно новой истории (удаляем 160 МБ мусора навсегда)
git checkout --orphan latest_branch
git add -A
git commit -am "Initial clean J.A.R.V.I.S. Android build"

# 3. Переименование веток
git branch -D main
git branch -m main

# 4. Отправка на GitHub
echo "Pushing to GitHub... (This should take 2 seconds now)"
git push -f origin main

echo "--- DONE! Check your GitHub Actions tab for the APK build ---"
