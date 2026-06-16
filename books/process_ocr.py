import os
import re
import json
import subprocess
from collections import defaultdict

TESSERACT = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
TESSDATA = r'C:\Users\user\AppData\Local\Tesseract-OCR\tessdata'

FOLDERS = [
    "D:\\Книги\\Детская энциклопедия",
    "D:\\Книги\\Искусство",
    "D:\\Книги\\Металлы и наука",
    "D:\\Книги\\Однотомники классической литературы",
    "D:\\Книги\\Писатели о писателях",
    "D:\\Книги\\Продано2",
    "D:\\Книги\\Серия БВЛ",
    "D:\\Книги\\Серия ЖЗЛ",
    "D:\\Книги\\Серия История эстетики в памятниках и документах",
    "D:\\Книги\\Серия Матера современной прозы",
    "D:\\Книги\\Снятые",
    "D:\\Книги",
]

def get_lot_key(filename):
    name = os.path.splitext(filename)[0]
    name = re.sub(r'[\(\)\[\]]', '', name)
    name = re.sub(r'_\d+$', '', name)
    name = re.sub(r'\(\d+\)$', '', name)
    return name

def group_files_by_lot(folder):
    lots = defaultdict(list)
    if not os.path.exists(folder):
        return lots
    for f in os.listdir(folder):
        fpath = os.path.join(folder, f)
        if not os.path.isfile(fpath):
            continue
        ext = os.path.splitext(f)[1].lower()
        if ext not in ('.jpg', '.jpeg', '.png'):
            continue
        lot = get_lot_key(f)
        lots[lot].append(f)
    for lot in lots:
        lots[lot].sort()
    return dict(lots)

def ocr_image(image_path):
    try:
        result = subprocess.run(
            [TESSERACT, image_path, 'stdout',
             '--tessdata-dir', TESSDATA,
             '-l', 'rus',
             '--psm', '6'],
            capture_output=True, text=True, timeout=120
        )
        text = result.stdout
        if len(text.strip()) < 10:
            text = subprocess.run(
                [TESSERACT, image_path, 'stdout',
                 '--tessdata-dir', TESSDATA,
                 '-l', 'rus',
                 '--psm', '3'],
                capture_output=True, text=True, timeout=120
            ).stdout
        return text.strip()
    except:
        return ""

def extract_meaningful_lines(text, min_len=10):
    lines = [l.strip() for l in text.split('\n') if l.strip()]
    meaningful = []
    for line in lines:
        cleaned = re.sub(r'[^\w\s.,:;!?«»()\-]', '', line).strip()
        if len(cleaned) >= min_len:
            meaningful.append(cleaned)
    return meaningful

results = {}

for folder in FOLDERS:
    folder_name = os.path.basename(folder)
    print(f"\n=== {folder_name} ===")
    lots = group_files_by_lot(folder)
    print(f"  Lots: {len(lots)}, Files: {sum(len(v) for v in lots.values())}")
    
    for lot_key, files in lots.items():
        best_text = ""
        best_lines = []
        for fname in files:
            fpath = os.path.join(folder, fname)
            text = ocr_image(fpath)
            lines = extract_meaningful_lines(text)
            if len(lines) > len(best_lines):
                best_text = text
                best_lines = lines
        
        if lot_key not in results:
            results[lot_key] = {
                'series': folder_name if folder != "D:\\Книги" else "",
                'files': [],
                'ocr_text': '',
                'meaningful_lines': []
            }
        
        results[lot_key]['files'].append({
            'folder': folder,
            'filenames': files
        })
        
        if len(best_lines) > len(results[lot_key]['meaningful_lines']):
            results[lot_key]['ocr_text'] = best_text
            results[lot_key]['meaningful_lines'] = best_lines

        if best_lines:
            print(f"  {lot_key}: {best_lines[0][:100]}")

with open('ocr_results.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

print(f"\nDone! Processed {len(results)} unique lots.")
