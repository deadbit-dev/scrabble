local dict = {}

function dict.find_words_by_prefix(trie, prefix)
    local function recursive_search(node, currentWord, resultTable)
        if node.complete then
            table.insert(resultTable, currentWord)
        end

        for char, childNode in pairs(node.children) do
            recursive_search(childNode, currentWord .. char, resultTable)
        end
    end

    local currentNode = trie
    for i = 1, #prefix do
        local char = prefix:sub(i, i)
        if currentNode[char] then
            currentNode = currentNode[char]
        else
            return {}
        end
    end

    local foundWords = {}
    recursive_search(currentNode, prefix, foundWords)
    return foundWords
end

-- function dict.word_exists(trie, word)
--     local current_node = trie
--     for i = 1, #word do
--         local char = word:sub(i, i)
--         if not current_node[char] then
--             return false
--         end
--         current_node = current_node[char]
--     end
--     return current_node.complete == true
-- end

function dict.word_exists(trie, word)
    local node = trie
    for i = 1, #word do
        local char = word:sub(i, i)
        if not node[char] then
            return false
        end
        -- Если это не последняя буква, переходим в children
        if i < #word then
            node = node[char].children
        else
            -- Для последней буквы проверяем complete в текущем узле
            node = node[char]
        end
    end
    return node.complete == true
end

function dict.find_words_by_pattern(trie, pattern)
    local results = {}

    local function pattern_search(node, currentWord, patternIndex)
        if patternIndex > #pattern then
            if node.complete then
                table.insert(results, currentWord)
            end
            return
        end

        local currentChar = pattern:sub(patternIndex, patternIndex)

        if currentChar == "?" then
            for char, childNode in pairs(node.children) do
                pattern_search(childNode, currentWord .. char, patternIndex + 1)
            end
        else
            if node[currentChar] then
                pattern_search(node[currentChar], currentWord .. currentChar, patternIndex + 1)
            end
        end
    end

    pattern_search(trie, "", 1)
    return results
end

function dict.count_words(trie)
    local count = 0

    local function count_recursive(node)
        if node.complete then
            count = count + 1
        end

        for _, childNode in pairs(node.children) do
            count_recursive(childNode)
        end
    end

    for _, firstNode in pairs(trie) do
        if type(firstNode) == "table" then
            count_recursive(firstNode)
        end
    end

    return count
end

return dict
