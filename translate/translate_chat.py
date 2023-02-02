import re
from deep_translator import GoogleTranslator
from pathlib import Path
from itertools import takewhile

target_language_code = "de"
input_file = Path(r"../userraw/maps/mp/bots/_bot_language_en.gsc") 
output_file = str(input_file).split("_en")[0] + f"_{target_language_code}.gsc"
translator_replacements = {
  # "a": "ae",
  # "ö": "oe",
  # "ü": "ue",
  # "ß": "ss",
}
translator = GoogleTranslator(source='auto', target=target_language_code)

def lstripped(s):
    return ''.join(takewhile(str.isspace, s))
def rstripped(s):
    return ''.join(reversed(tuple(takewhile(str.isspace, reversed(s)))))
def stripped(s):
    return lstripped(s), rstripped(s)
def translate_text(text):
    if not text: return
    translated = translator.translate(text)
    if not translated: return
    for find, replace in translator_replacements.items():
      translated = translated.replace(find, replace)
    return translated

with open(input_file, "r") as file:
    content = file.readlines()

done = 0;failed = 0
regexes = [
  re.compile(r'"\) return "(.+)";')
]
linecount = len(content)-5
for i, line in enumerate(content):
  for regex in regexes:
    matches = regex.findall(line)
    for match in matches:
      try:
        original_text = match
        if len(original_text) < 3: continue
        print(f"[{done}/{linecount}] \"{original_text}\"")
        translated_text = translate_text(target_language_code, original_text)
        if not translated_text:
          failed += 1
          continue
        print(f"=> \"{translated_text}\"")
        content[i] = line.replace(original_text, lstripped(original_text) + translated_text + rstripped(original_text))
        done += 1
      except Exception as ex:
        failed += 1
        print(ex)

print(f"Translated {done} items, saving")
with open(output_file, 'w', encoding='utf-8') as f:
    f.writelines(content)
