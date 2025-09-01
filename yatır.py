# -*- coding: utf-8 -*-
# tum_satirlari_virgullu.py
# Amaç: input.txt içindeki tüm satırları tek satırda, virgülle ayırarak yazmak.

from pathlib import Path

# >>> BURAYI DÜZENLE <<<
INPUT_FILE  = Path(r"sss.txt")      # Girdi dosyan
OUTPUT_FILE = Path(r"output.txt")   # Çıktı dosyan

def main():
    if not INPUT_FILE.exists():
        raise FileNotFoundError(f"Girdi bulunamadı: {INPUT_FILE}")

    # Satırları oku, boşları at, baş/son boşlukları temizle
    lines = [line.strip() for line in INPUT_FILE.read_text(encoding="utf-8").splitlines() if line.strip()]

    # Virgülle birleştir
    tek_satir = ", ".join(lines)

    # Çıktıya yaz
    OUTPUT_FILE.write_text(tek_satir, encoding="utf-8")
    print(f"Bitti. Çıktı: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
