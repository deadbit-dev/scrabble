import threading

from ru_parser import parser_ru
from en_parser import parser_en

LANGS = {
    parser_ru,
    parser_en
}

def parse_langs():
    threads = [threading.Thread(target=lang) for lang in LANGS]
    for thread in threads:
        thread.start()


def main():
    parse_langs()


if __name__ == "__main__":
    main()