# Конфигурация TUI OpenCode

Файл: `tui.json`

```json
{
  "$schema": "https://opencode.ai/tui.json",
  "theme": "catppuccin",
  "mouse": true,
  "diff_style": "auto",
  "keybinds": {
    "status_view": "<leader>s",
    "display_thinking": "<leader>d"
  }
}
```

## Описание

- **theme** — Catppuccin тема
- **mouse** — поддержка мыши включена
- **diff_style** — авто-адаптация под ширину терминала
- **keybinds** — `<leader>s` для просмотра статуса, `<leader>d` для отображения thinking
