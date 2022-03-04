"""!@file formatters.py
@author = magnus.ersdal@uib.no
@brief file for holding formatting functions.

"""


def format_page_data_to_nice_string(page_data):
    """Expect a list of bytes (ints)"""
    words = []
    strings = []
    for chunk in list(chunks(page_data, 4)):
        word = 0
        chunk.reverse()  # No return type.
        for i, x in enumerate(chunk):
            word = word | x << i * 8
        words.append("0x{:08X}, ".format(word))
    for hexchunk in chunks(words, 4):
        strings.append("".join(hexchunk) + "\n")
    for i, line in enumerate(strings):
        try:
            if list(set(strings[i:])) == [line]:
                strings = strings[:i + 1]
                strings.append("... to end (i = {}) \n".format(i + 1))
                break
        except IndexError:
            pass  # ignore indexerror
    return "".join(strings)


def chunks(data, n):
    for i in range(0, len(data), n):
        yield data[i:i + n]
