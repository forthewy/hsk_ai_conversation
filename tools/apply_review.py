import json

# 기존 파일
with open("assets/translations/1_ko.json", "r", encoding="utf-8") as f:
    original = json.load(f)

# 수정 내용
with open("tools/reviews/1_ko_patch.json", "r", encoding="utf-8") as f:
    patch = json.load(f)

count = 0
for key, value in patch.items():
    if key in original:
        original[key] = value
        count += 1
    else:
        print(f"없는 Key: {key}")

print(f"{count}개 수정 완료")

with open("1_ko_fixed.json", "w", encoding="utf-8") as f:
    json.dump(original, f, ensure_ascii=False, indent=2)