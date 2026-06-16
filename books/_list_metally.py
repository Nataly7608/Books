# -*- coding: utf-8 -*-
import json, os

with open('ocr_results_full.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Find lots where folder contains "Металлы"
target = [(k, v) for k, v in data.items() if 'еталл' in v.get('folder', '')]
target.sort(key=lambda x: x[0])

print(f"Total lots in Металлы: {len(target)}\n")

for k, v in target:
    lines = v.get('ocr_lines', [])
    if lines:
        print(f"{k}: {' || '.join(lines)}")
    else:
        print(f"{k}: (no OCR text)")
