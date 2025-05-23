import json
import requests
import threading
import logging
import time

from bs4 import BeautifulSoup

words = {}

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("log.log"),
        logging.StreamHandler()
    ]
)

logging.basicConfig(
    level=logging.FATAL,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("log.log"),
        logging.StreamHandler()
    ]
)

CYRILLIC_ALPHABET = ['а', 'б', 'в', 'г', 'д', 'е', 'ё', 'ж', 'з', 'и', 'й', 'к', 'л', 'м', 'н', 'о', 'п', 'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч', 'ш', 'щ', 'ъ', 'ы', 'ь', 'э', 'ю', 'я']
COUPLE_CYRILLIC_LETTERS = [letter + second_letter for letter in CYRILLIC_ALPHABET for second_letter in CYRILLIC_ALPHABET]

WIKI_URL = 'https://ru.wiktionary.org'
GOOGLE_URL = 'https://www.google.com/search?q='
GRAMOTA_URL = 'https://gramota.ru/'


def check_wiki_noun(word_data):
    data = word_data.find_all('a')
    for a in data:
        if a.get_text().lower() == 'существительное':
            return True
    return False

def check_google_noun(word):
    url = GOOGLE_URL + '+'.join(f'{word} часть речи'.split())
    print(url)
    data = requests.get(url)
    soup = BeautifulSoup(data.text, features="html.parser")
    text = soup.find('div', class_='v9i61e').get_text()
    return (text.lower().find('существительное') != -1)

def check_gramota_noun(word):
    search_url = GRAMOTA_URL + 'poisk?query=' + word + '&mode=slovari' + '&simple=1'
    logging.info(f'SEARCH: {search_url}')
    search_data = requests.get(search_url)
    search_soup = BeautifulSoup(search_data.text, features="html.parser")
    snippets = search_soup.find('div', class_='snippets')
    if snippets == None:
        return False
    for elm in snippets.find_all('a', class_='title'):
        url = elm.get('href')
        meta_url = GRAMOTA_URL + url if url.find('http') == -1 else url
        meta_data = requests.get(meta_url)
        meta_soup = BeautifulSoup(meta_data.text, features="html.parser")
        meta_gram = meta_soup.find('div', class_='gram')
        if meta_gram == None:
            if(meta_data.status_code == 503):
                time.sleep(5);
                return check_gramota_noun(word)
            else:
                raise Exception(f'{meta_data.status_code} | {meta_url} | {word}')
            
        if meta_gram.get_text().lower().find('существительное') != -1:
            return True
    return False


def check_wiki_letter(word_data):
    ps = word_data.find_all('p')
    for p in ps:
        text = p.get_text()
        if text.lower().find('буква кириллицы') != -1:
            return True
    return False


def check_wiki_name(word_data):
    ps = word_data.find_all('p')
    for p in ps:
        text = p.get_text()
        if text.lower().find('имя собственное') != -1:
            return True
    return False


def check_wiki_space(word):
    return word.find(' ') != -1


def check_wiki_signs(word):
    return word.find('-') != -1


def parse_wiki_page(url):
    data = requests.get(url)
    soup = BeautifulSoup(data.text, features="html.parser")
    return soup.find("div", class_="mw-content-ltr mw-parser-output")


def parse_wiki_letter_words(page):
    if page == None:
        return
    for target in page.find_all('p'):
        if target.a == None:
            continue
        for letters in COUPLE_CYRILLIC_LETTERS:
            if target.a.get_text() != letters:
                continue
            letter_url = WIKI_URL + target.a.get('href')
            letter_data = parse_wiki_page(letter_url)
            for [word, word_data] in parse_wiki_letter_words(letter_data):
                yield (word, word_data)
            break
    for word_info in page.find_all('li'):
        word_url = WIKI_URL + word_info.a.get('href')
        word = word_info.a.get_text().lower()
        word_data = parse_wiki_page(word_url)
        yield (word, word_data)


# TODO: check word on other rules and finaly check on noun
def parse_wiki_letter(letter):
    global words
    base_url = WIKI_URL + '/wiki/Индекс:Русский_язык/'
    letter_url = base_url + letter.upper()
    letter_data = parse_wiki_page(letter_url)
    for [word, word_data] in parse_wiki_letter_words(letter_data):
        if word_data == None:
            logging.info('SKIP NONE')
            continue
        if check_wiki_letter(word_data):
            logging.info(f'SKIP LETTER: {word}')
            continue
        if check_wiki_name(word_data):
            logging.info(f'SKIP NAME: {word}')
            continue
        if check_wiki_space(word):
            logging.info(f'SKIP WORD WITH SPACE: {word}')
            continue
        if check_wiki_signs(word):
            logging.info(f'SKIP WORD WITH SIGNS: {word}')
            continue
        if not check_gramota_noun(word):
            logging.info(f'SKIP NOT NOUN: {word}')
            continue
        words[word] = {}
        logging.info(f'FOUND WORD: {word}')


def parser_ru():
    global words
    threads = [threading.Thread(target=parse_wiki_letter, args=(letter,)) for letter in CYRILLIC_ALPHABET]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    for letter in CYRILLIC_ALPHABET:
        parse_wiki_letter(letter)
    with open('ru.json', 'w', encoding='utf8') as file:
        json.dump(words, file, ensure_ascii=False)


def main():
    try:
        parser_ru()
    except Exception as err:
        logging.fatal(err)


if __name__ == "__main__":
    main()