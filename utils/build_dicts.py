"""
Build trie files from plain word-list JSONs.

Usage:
    python3 utils/build_dicts.py          # build all
    python3 utils/build_dicts.py en       # build English only
    python3 utils/build_dicts.py ru       # build Russian only

Input:  dicts/{lang}.json   — plain JSON array of words
Output: dicts/{lang}_trie.json
"""

import json
import os
import sys

DICTS_DIR = os.path.join(os.path.dirname(__file__), '..', 'dicts')


def build_trie(words):
    root = {}
    for word in words:
        node = root
        for i, ch in enumerate(word):
            if ch not in node:
                node[ch] = {'complete': False, 'children': {}}
            if i == len(word) - 1:
                node[ch]['complete'] = True
            node = node[ch]['children']
    return root


def build(lang):
    src = os.path.join(DICTS_DIR, f'{lang}.json')
    dst = os.path.join(DICTS_DIR, f'{lang}_trie.json')

    print(f'[{lang}] reading {src} ...')
    with open(src, encoding='utf-8') as f:
        words = json.load(f)
    print(f'[{lang}] {len(words)} words')

    print(f'[{lang}] building trie ...')
    trie = build_trie(words)

    print(f'[{lang}] saving {dst} ...')
    with open(dst, 'w', encoding='utf-8') as f:
        json.dump(trie, f, ensure_ascii=False, separators=(',', ':'))

    size_kb = os.path.getsize(dst) // 1024
    print(f'[{lang}] done — {size_kb} KB')


if __name__ == '__main__':
    langs = sys.argv[1:] or ['en', 'ru']
    for lang in langs:
        build(lang)
