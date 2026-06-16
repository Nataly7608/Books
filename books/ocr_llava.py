import base64
import json
import os
import sys
import time
import urllib.request
import urllib.error

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "llava:7b"
TARGET = r"D:\Книги\Писатели о писателях"
OUTPUT = r"C:\Users\user\Documents\pa-finance.2\books\ocr_llava_results.json"
MAX_SIZE = 512
REQUEST_TIMEOUT = 300

def resize_image_if_needed(image_path):
    try:
        from PIL import Image
        img = Image.open(image_path)
        w, h = img.size
        if w > MAX_SIZE or h > MAX_SIZE:
            ratio = min(MAX_SIZE / w, MAX_SIZE / h)
            new_w, new_h = int(w * ratio), int(h * ratio)
            img = img.resize((new_w, new_h), Image.LANCZOS)
            temp_path = image_path + ".temp.jpg"
            img.save(temp_path, "JPEG", quality=85)
            return temp_path
    except ImportError:
        pass
    return image_path

def image_to_base64(image_path):
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def ask_llava(image_path):
    temp_path = resize_image_if_needed(image_path)
    try:
        img_b64 = image_to_base64(temp_path)
        prompt = (
            "Посмотри на изображение обложки книги. "
            "Напиши только ФИО автора и название книги на русском языке "
            "в формате: Автор: ... | Название: ... "
            "Если не можешь определить, напиши 'не определено'."
        )
        payload = json.dumps({
            "model": MODEL,
            "prompt": prompt,
            "images": [img_b64],
            "stream": False
        }).encode("utf-8")

        req = urllib.request.Request(
            OLLAMA_URL,
            data=payload,
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            return result.get("response", "").strip()
    finally:
        if temp_path != image_path and os.path.exists(temp_path):
            os.remove(temp_path)

def main():
    files = sorted([
        f for f in os.listdir(TARGET)
        if f.lower().endswith(('.jpg', '.jpeg', '.png'))
    ])

    if not files:
        print("Нет файлов изображений в", TARGET)
        return

    results = {}
    total = len(files)

    for idx, fname in enumerate(files, 1):
        fpath = os.path.join(TARGET, fname)
        print(f"[{idx}/{total}] {fname} ... ", end="", flush=True)
        try:
            response = ask_llava(fpath)
            print(response[:120])
            results[fname] = {
                "file": fname,
                "llava_response": response
            }
        except Exception as e:
            print(f"ОШИБКА: {e}")
            results[fname] = {
                "file": fname,
                "llava_response": f"ERROR: {e}"
            }
        time.sleep(1)

    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    print(f"\nРезультаты сохранены в {OUTPUT}")

if __name__ == "__main__":
    main()
