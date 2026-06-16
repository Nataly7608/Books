# Установка Playwright MCP

## 1. Инициализация npm в корне проекта

```powershell
cd C:\Users\user\Documents\pa-finance.2
npm init -y
```

## 2. Установка пакета @playwright/mcp

```powershell
npm install @playwright/mcp
```

## 3. Установка браузеров Playwright

```powershell
npx playwright install chromium
```

## 4. Настройка в opencode.json

Добавить в `books/opencode.json`:

```json
"mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "playwright-mcp"],
      "cwd": "..",
      "enabled": true
    }
}
```

## 5. Добавить .gitignore

```powershell
echo "node_modules/" > .gitignore
```

## 6. Проверка

```powershell
# Проверить, что MCP сервер запускается
npx playwright-mcp --version
```

После настройки при запуске OpenCode из папки `books/` будут доступны инструменты `playwright_*` (навигация по страницам, скриншоты, клики и т.д.).
