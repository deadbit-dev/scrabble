import json


def build_trie(words):
    """
    Строит префиксное дерево (trie) из списка слов
    """
    trie = {}
    
    for word in words:
        # NOTE: Пропускаем пустые слова и слова с недопустимыми символами
        if not word or not word.isalpha() or not word.islower():
            continue
            
        node = trie
        for i, char in enumerate(word):
            if char not in node:
                node[char] = {
                    "complete": False,
                    "children": {}
                }
            
            # NOTE: Если это последний символ слова, помечаем узел как полное слово
            if i == len(word) - 1:
                node[char]["complete"] = True
            else:
                # NOTE: Переходим к следующему узлу
                node = node[char]["children"]
    
    return trie


def load_words_from_file(filename):
    """
    Загружает слова из JSON файла
    """
    words = []
    
    try:
        if not filename.endswith('.json'):
            print(f"Неверный формат файла, ожидаем .json")
            return
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
            # Если это словарь с ключом 'words', извлекаем слова
            if isinstance(data, dict) and 'words' in data:
                words = data['words']
            elif isinstance(data, list):
                words = data
            else:
                print("Неверный формат JSON файла")
                return []
                
        print(f"Загружено {len(words)} слов")
        return words
        
    except FileNotFoundError:
        print(f"Файл {filename} не найден")
        return []
    except Exception as e:
        print(f"Ошибка при загрузке файла: {e}")
        return []


def save_trie_to_file(trie, filename):
    """
    Сохраняет trie в JSON файл
    """
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(trie, f, ensure_ascii=False, indent=2)
        print(f"Древовидная структура сохранена в {filename}")
    except Exception as e:
        print(f"Ошибка при сохранении файла: {e}")


def main():
    words = load_words_from_file("dicts/en.json")
    if not words:
        print("Не удалось загрузить слова. Используем примерный список.")
        return

    trie = build_trie(words)
    save_trie_to_file(trie, "dicts/en_trie.json")

if __name__ == "__main__":
    main()