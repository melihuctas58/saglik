import json
from pathlib import Path

# >>> Dosya yollarını buraya yaz
INPUT_JSON = Path(r"malzemeler.json")   # JSON dosyanın yolu
OUTPUT_TXT = Path(r"primary_names.txt")  # Çıktı TXT dosyası

def main():
    # JSON'u oku
    with open(INPUT_JSON, "r", encoding="utf-8") as f:
        data = json.load(f)

    # primary_name değerlerini topla
    names = []
    for item in data:
        try:
            names.append(item["core"]["primary_name"])
        except KeyError:
            pass  # core veya primary_name yoksa atla

    # TXT'ye satır satır yaz
    with open(OUTPUT_TXT, "w", encoding="utf-8") as f:
        for name in names:
            f.write(name + "\n")

    print(f"{len(names)} adet primary_name {OUTPUT_TXT} dosyasına yazıldı.")

if __name__ == "__main__":
    main()
