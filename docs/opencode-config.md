# Конфигурация OpenCode

Файл: `opencode.json`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/llava:7b",
  "small_model": "ollama/llava:7b",
  "instructions": ["AGENTS.md"],
  "provider": {
    "ollama": {
      "options": {
        "baseURL": "http://localhost:11434/api"
      }
    }
  },
  "compaction": {
    "auto": true,
    "prune": false,
    "tail_turns": 2
  }
}
```

## Описание

- **model** — основная модель (Ollama/llava:7b)
- **small_model** — лёгкая модель для простых задач
- **instructions** — подключён AGENTS.md как системные инструкции
- **provider.ollama** — локальный Ollama на localhost:11434
- **compaction** — авто-компактизация контекста включена, хвост — 2 последних оборота
