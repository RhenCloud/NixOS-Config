#!/usr/bin/env python3
import argparse
import re
from pathlib import Path


HEADER = """# Rime dictionary
# encoding: utf-8
#
# 由 keytao-custom-phrase-sync 生成，手动修改会在下次同步时被覆盖。
---
name: keytao.custom.user
version: \"1.0\"
sort: by_weight
use_preset_vocabulary: false
columns:
  - text
  - code
  - weight
...
"""

CODE = re.compile(r"^[a-z]{1,6}$")


def parse_entries(path):
    entries = {}
    if not path.exists():
        return entries

    for line in path.read_text(encoding="utf-8").splitlines():
        fields = line.split("\t")
        if len(fields) != 3:
            continue
        text, code, weight = fields
        if not 2 <= len(text) <= 6 or not CODE.fullmatch(code) or "#" in text:
            continue
        try:
            entries[text, code] = max(entries.get((text, code), 0), int(weight))
        except ValueError:
            continue
    return entries


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()

    entries = parse_entries(args.source)
    output = HEADER + "".join(
        f"{text}\t{code}\t{max(weight, 1000000)}\n"
        for (text, code), weight in sorted(entries.items())
    )
    args.destination.write_text(output, encoding="utf-8")


if __name__ == "__main__":
    main()
