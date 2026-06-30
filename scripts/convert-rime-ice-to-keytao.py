#!/usr/bin/env python3
"""
从 rime-ice base.dict.yaml 提取二字词并转换为键道6 编码

Usage: convert-rime-ice-to-keytao.py <rime_ice_cn_dicts_dir> <keytao_phrase_dict> <keytao_single_dict> <output_path>

rime_ice_cn_dicts_dir: rime-ice 的 cn_dicts 目录（包含 base.dict.yaml 等）
keytao_phrase_dict: 键道词组词典 (keytao.phrase.dict.yaml)
keytao_single_dict: 键道单字词典 (keytao.single.dict.yaml)  
output_path: 输出文件路径
"""

import re
import sys
import os

def parse_yaml_header(lines):
    """解析 Rime YAML 词典文件的 header 部分，返回 (header_lines, entry_start)"""
    in_header = True
    header_lines = []
    for i, line in enumerate(lines):
        if in_header:
            header_lines.append(line)
            if line.strip() == "...":
                in_header = False
                return header_lines, i + 1
    return header_lines, len(lines)

def parse_entry(line):
    """解析 Rime 词典条目行，返回 (text, code, weight) 或 None"""
    line = line.strip()
    if not line or line.startswith("#"):
        return None
    parts = line.split("\t")
    if len(parts) < 2:
        return None
    text = parts[0]
    code = parts[1]
    weight = int(parts[2]) if len(parts) >= 3 and parts[2].isdigit() else 0
    return text, code, weight

def build_single_lookup(single_path):
    """
    从键道单字词典构建 汉字→最短编码 的查找表
    返回: { char: shortest_code }
    """
    lookup = {}
    with open(single_path, encoding="utf-8") as f:
        lines = f.readlines()
    _, entry_start = parse_yaml_header(lines)
    for line in lines[entry_start:]:
        parsed = parse_entry(line)
        if parsed is None:
            continue
        char, code, _ = parsed
        if len(char) != 1:
            continue
        # 取最短的编码作为首选
        if char not in lookup or len(code) < len(lookup[char]):
            lookup[char] = code
    return lookup

def build_phrase_set(phrase_path):
    """
    构建已有词组集合用于去重
    返回: { (text, code): True }
    """
    existing = set()
    with open(phrase_path, encoding="utf-8") as f:
        lines = f.readlines()
    _, entry_start = parse_yaml_header(lines)
    for line in lines[entry_start:]:
        parsed = parse_entry(line)
        if parsed is None:
            continue
        text, code, _ = parsed
        existing.add((text, code))
    return existing

def generate_code(word, single_lookup):
    """
    为二字词生成键道编码
    规则: 取每个字的首2码拼接
    返回: code 或 None (如果某个字找不到)
    """
    if len(word) != 2:
        return None
    c1, c2 = word
    code1 = single_lookup.get(c1)
    code2 = single_lookup.get(c2)
    if code1 is None or code2 is None:
        return None
    return code1[:2] + code2[:2]

def parse_rime_ice_entry(line):
    """解析 rime-ice 词典条目，返回 (text, pinyins, weight) 或 None"""
    line = line.strip()
    if not line or line.startswith("#"):
        return None
    parts = line.split("\t")
    if len(parts) < 2:
        return None
    text = parts[0]
    pinyins = parts[1]
    weight = int(parts[2]) if len(parts) >= 3 and parts[2].isdigit() else 0
    return text, pinyins, weight

def main():
    if len(sys.argv) != 5:
        print(f"Usage: {sys.argv[0]} <rime_ice_cn_dicts_dir> <keytao_phrase_dict> <keytao_single_dict> <output_path>", file=sys.stderr)
        sys.exit(1)

    ice_dicts_dir = sys.argv[1]
    phrase_dict_path = sys.argv[2]
    single_dict_path = sys.argv[3]
    output_path = sys.argv[4]

    print("Building single character lookup...", file=sys.stderr)
    single_lookup = build_single_lookup(single_dict_path)

    print("Building phrase dedup set...", file=sys.stderr)
    phrase_set = build_phrase_set(phrase_dict_path)

    # 收集新条目
    new_entries = []  # [(text, code, weight)]
    seen = set()  # 去重用

    # 从 rime-ice 读取二字词
    ice_files = []
    if os.path.isdir(ice_dicts_dir):
        for fname in ["base.dict.yaml"]:
            path = os.path.join(ice_dicts_dir, fname)
            if os.path.isfile(path):
                ice_files.append(path)
        # 也尝试找其他词库文件
        for fname in os.listdir(ice_dicts_dir):
            path = os.path.join(ice_dicts_dir, fname)
            if fname.endswith(".dict.yaml") and fname not in ["base.dict.yaml"] and os.path.isfile(path):
                ice_files.append(path)

    for ice_path in ice_files:
        print(f"Processing {os.path.basename(ice_path)}...", file=sys.stderr)
        with open(ice_path, encoding="utf-8") as f:
            lines = f.readlines()
        _, entry_start = parse_yaml_header(lines)
        for line in lines[entry_start:]:
            parsed = parse_rime_ice_entry(line)
            if parsed is None:
                continue
            text, pinyins, weight = parsed
            if len(text) != 2:
                continue
            code = generate_code(text, single_lookup)
            if code is None:
                continue
            key = (text, code)
            if key in phrase_set or key in seen:
                continue
            seen.add(key)
            new_entries.append((text, code, weight))

    # 写入输出文件
    print(f"Writing {len(new_entries)} new entries to {output_path}...", file=sys.stderr)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(
            "# Rime dictionary\n"
            "# encoding: utf-8\n"
            "#\n"
            "# 从 rime-ice 转换而来的键道6 词组\n"
            "---\n"
            "name: ice2keytao\n"
            "version: \"1.0\"\n"
            "sort: by_weight\n"
            "use_preset_vocabulary: true\n"
            "columns:\n"
            "  - text\n"
            "  - code\n"
            "  - weight\n"
            "...\n"
        )
        for text, code, weight in new_entries:
            f.write(f"{text}\t{code}\t{weight}\n")

    print("Done!", file=sys.stderr)

if __name__ == "__main__":
    main()
