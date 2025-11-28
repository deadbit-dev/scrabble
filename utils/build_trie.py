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