# -*- coding: utf-8 -*-
import os, re, json, subprocess, sys
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed

TESSERACT = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
TESSDATA = r'C:\Users\user\AppData\Local\Tesseract-OCR\tessdata'

def get_lot_key(filename):
    name = os.path.splitext(filename)[0]
    name = re.sub(r'[()\[\]]', '', name)
    name = re.sub(r'_\d+$', '', name)
    return name

def ocr_file(fpath, timeout=25):
    try:
        r = subprocess.run(
            [TESSERACT, fpath, 'stdout', '--tessdata-dir', TESSDATA, '-l', 'rus', '--psm', '6'],
            capture_output=True, text=False, timeout=timeout
        )
        return r.stdout.decode('utf-8', errors='replace')
    except:
        return ""

def clean_ocr(text):
    lines = [l.strip() for l in text.split('\n') if l.strip() and len(l.strip()) > 5]
    clean = []
    for l in lines:
        c = re.sub(r'[^\w\s.,:;!?«»()\-\–\'\"\d]', ' ', l).strip()
        c = re.sub(r'\s+', ' ', c).strip()
        if len(c) > 10 and any(x in c.lower() for x in 'аеёиоуыэюя'):
            clean.append(c)
    return clean[:5]

base_dirs = ['D:\\Книги', 'D:\\Книги 3-лоты Наташи']
skip_dirs = {'Продано2', 'Снятые', 'Продано', 'Originals', 'output'}

all_lots = []
for base in base_dirs:
    if not os.path.exists(base):
        continue
    for entry in os.listdir(base):
        subpath = os.path.join(base, entry)
        if not os.path.isdir(subpath) or entry in skip_dirs:
            continue
        files = [f for f in os.listdir(subpath) if os.path.isfile(os.path.join(subpath, f))]
        image_files = [f for f in files if os.path.splitext(f)[1].lower() in ('.jpg','.jpeg','.png')]
        if not image_files:
            continue
        lots = defaultdict(list)
        for f in image_files:
            lots[get_lot_key(f)].append(f)
        for lk, lst in lots.items():
            candidates = [f for f in lst if re.search(r'_\d+$', os.path.splitext(f)[0])]
            if not candidates:
                candidates = [lst[0]]
            all_lots.append({
                'folder': entry,
                'lot': lk,
                'files': lst,
                'folder_path': subpath,
                'candidates': candidates[:2]
            })

print(f"Total lots: {len(all_lots)}")
sys.stdout.flush()

results = {}
def process_lot(lot_info):
    best_text = ""
    for fname in lot_info['candidates']:
        fpath = os.path.join(lot_info['folder_path'], fname)
        text = ocr_file(fpath)
        if len(text) > len(best_text):
            best_text = text
    lines = clean_ocr(best_text)
    key = f"{lot_info['folder']}/{lot_info['lot']}"
    return key, {
        'folder': lot_info['folder'],
        'lot': lot_info['lot'],
        'files': lot_info['files'],
        'ocr_lines': lines
    }

with ThreadPoolExecutor(max_workers=4) as pool:
    fut_map = {pool.submit(process_lot, l): l for l in all_lots}
    done = 0
    for f in as_completed(fut_map):
        done += 1
        key, data = f.result()
        results[key] = data
        if data['ocr_lines']:
            print(f"[{done}/{len(all_lots)}] {key}: {data['ocr_lines'][0][:80]}")
        else:
            print(f"[{done}/{len(all_lots)}] {key}: (no text)")
        sys.stdout.flush()

out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ocr_results_full.json')
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

print(f"\nDone! Processed {len(results)} lots. Saved to {out_path}")
