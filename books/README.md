# Проект: Переименование файлов книг для продажи

## Описание

Набор скриптов для OCR-распознавания обложек книг и переименования файлов фотографий для лотов продажи на торговой площадке.

Исходные файлы — фотографии книг на диске `D:\Книги\...`. Требуется переименовать их в формат: `<исходное_имя>_<номер>_<ФИО автора>_<Название книги>.<расширение>`

## Структура

```
books/
├── process_ocr.py              # OCR-пайплайн через Tesseract
├── ocr_results_full.json       # Результаты OCR (все папки)
├── rename_table.md             # Таблица переименования (Металлы и наука)
├── rename_table_pisatelei.md   # Таблица переименования (Писатели о писателях)
├── rename_pisatelei.py         # Скрипт переименования для Писатели о писателях
├── README_task.md              # Исходное описание задачи
├── README.md                   # Данный файл
└── *.ps1                       # Вспомогательные PowerShell-скрипты
```

## Выполненные работы

### Папка: Писатели о писателях (15 файлов, 14 переименовано, 1 удалён)

1. **Попытка OCR через Llava 7b** — модель оказалась слишком медленной (~5 мин на файл) и не смогла распознать текст на обложках.

2. **Двухэтапный подход:**
   - Составлена таблица исходных имён файлов (`rename_table_pisatelei.md`)
   - Пользователь заполнил ФИО авторов и названия книг
   - Скрипт `rename_pisatelei.py` выполнил переименование

3. **Использованные команды:**

   OCR через Tesseract:
   ```powershell
   & "C:\Program Files\Tesseract-OCR\tesseract.exe" "<файл>" stdout --tessdata-dir "$env:LOCALAPPDATA\Tesseract-OCR\tessdata" -l rus --psm 6
   ```

   OCR через Ollama + Llava 7b (API):
   ```powershell
   curl -X POST http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{\"model\":\"llava:7b\",\"prompt\":\"...\",\"images\":[\"...\"],\"stream\":false}'
   ```

   Переименование файлов (Python):
   ```powershell
   python books/rename_pisatelei.py
   ```

   Проверка содержимого папки:
   ```powershell
   Get-ChildItem -LiteralPath "D:\Книги\Писатели о писателях"
   ```
