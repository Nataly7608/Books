# -*- coding: utf-8 -*-
import os, re, json, subprocess, sys, time
from collections import defaultdict

TESSERACT = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
TESSDATA = r'C:\Users\user\AppData\Local\Tesseract-OCR\tessdata'

def get_lot_key(filename):
    name = os.path.splitext(filename)[0]
    name = re.sub(r'[()\[\]]', '', name)
    name = re.sub(r'_\d+$', '', name)
    return name

def ocr_file(fpath):
    try:
        r = subprocess.run(
            [TESSERACT, fpath, 'stdout', '--tessdata-dir', TESSDATA, '-l', 'rus', '--psm', '6'],
            capture_output=True, text=False, timeout=60
        )
        return r.stdout.decode('utf-8', errors='replace')
    except:
        return ""

def process_folder(folder_path, results):
    folder_name = os.path.basename(folder_path)
    print(f"Processing: {folder_name}")
    sys.stdout.flush()
    
    try:
        all_files = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]
    except:
        return
    
    image_files = []
    for f in all_files:
        ext = os.path.splitext(f)[1].lower()
        if ext in ('.jpg', '.jpeg', '.png'):
            image_files.append(f)
    
    if not image_files:
        return
    
    lots = defaultdict(list)
    for f in image_files:
        lots[get_lot_key(f)].append(f)
    
    for lot_key in sorted(lots.keys()):
        files = lots[lot_key]
        candidates = [f for f in files if re.search(r'_\d+$', os.path.splitext(f)[0])]
        if not candidates:
            candidates = files
        
        best_text = ""
        for fname in candidates[:2]:
            fpath = os.path.join(folder_path, fname)
            text = ocr_file(fpath)
            if len(text) > len(best_text):
                best_text = text
        
        lines = [l.strip() for l in best_text.split('\n') if l.strip() and len(l.strip()) > 5]
        clean = []
        for l in lines:
            c = re.sub(r'[^\w\s.,:;!?«»()\-\–\'\"\d]', ' ', l).strip()
            c = re.sub(r'\s+', ' ', c).strip()
            if len(c) > 10:
                clean.append(c)
        
        key = f"{folder_name}/{lot_key}"
        results[key] = {
            'folder': folder_name,
            'lot': lot_key,
            'files': files,
            'ocr_lines': clean[:10]
        }
        
        print(f"  {lot_key}: {clean[0][:80] if clean else '(no text)'}")
        sys.stdout.flush()

results = {}

# Process subdirectories of the books folders
base = 'D:\\'
try:
    all_dirs = os.listdir(base)
except:
    print("Cannot access D:\\")
    sys.exit(1)

book_dirs = []
for d in all_dirs:
    dpath = os.path.join(base, d)
    if os.path.isdir(dpath) and ('Книг' in d or 'книг' in d):
        book_dirs.append(dpath)

print(f"Found book directories: {book_dirs}")

for bd in book_dirs:
    print(f"\n{'='*60}")
    print(f"Processing: {bd}")
    
    # Process subdirectories
    try:
        entries = os.listdir(bd)
    except:
        continue
    
    for entry in sorted(entries):
        subpath = os.path.join(bd, entry)
        if os.path.isdir(subpath):
            # Don't process Продано2 and Снятые (already sold/removed)
            if 'Продано' in entry or 'Снятые' in entry or 'Снят' in entry:
                print(f"  Skipping: {entry}")
                continue
            process_folder(subpath, results)
    
    # Process root files
    process_folder(bd, results)

# Save results
with open('ocr_results_full.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

print(f"\n{'='*60}")
print(f"Done! Processed {len(results)} lots.")
print(f"Results saved to ocr_results_full.json")
