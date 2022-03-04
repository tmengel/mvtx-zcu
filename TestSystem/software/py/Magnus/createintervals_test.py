from itertools import chain
import hypothesis
from hypothesis import given, note, settings,assume, example, strategies as st


def create_intervals(bad_blocks):
    """
    assumes that at least one of the ten first and ten last blocks on a chip is OK
    :param  list bad_blocks: list of bad blocks on flash memory
    :return: good memory areas in tuples of page addresses
    :rtype: list[tuple[int,int]]"""

    MINRANGE = 97

    def not_sequencial(tp):
        """filter function, returns if a,b is not differing by one"""
        a, b = tp
        return b - a != 1

    def good_range(tp):
        """returns if the space between a and b is less than MINRANGE (100 ish)
        """
        a, b = tp
        return abs(a - b) > MINRANGE

    allblocks_set = list(range(2 ** 13 + 1))  # set(range(start=0x40, stop=2 ** 13 + 1, step=0x40))
    filtered_blocks = [x for x in allblocks_set if x not in bad_blocks]

    win = zip(filtered_blocks, filtered_blocks[1:])  # sliding window of size 2
    indices = list(chain(*filter(not_sequencial, win)))

    # fix start and end of list for special cases
    if 2 ** 13 not in indices:
        for i in range(10):  # try 10
            if 2 ** 13 - i not in bad_blocks:
                indices.append(2 ** 13 - i)
                break
    if 1 not in indices:
        for i in range(10):
            if 1 + i not in bad_blocks:
                indices = [1 + i] + indices
                break
    # then filter for range > 100:
    assert len(indices) >= 2, f"error on {indices}"
    win2 = zip(indices, indices[1:])  # sliding window of size 2
    indices_in_range = list(filter(good_range, win2))

    # convert to page addresses !
    page_address_tuples = []
    for tp in indices_in_range:
        a, b = tp
        memory_range = (a * 0x40, b * 0x40 + 0x39)
        page_address_tuples.append(memory_range)

    return page_address_tuples


@given(st.lists(st.integers()))
@settings(max_examples=500)
@example([2 ** 13])
@example([0])
@example([56])
@example([1, 2 ** 13])
def test_notnone(ls):
    val = create_intervals(ls)
    res = list(chain(*create_intervals(ls)))
    assert val is not None
    assert res


@given(st.lists(st.integers(0, 2 ** 22)))
def test_ordered(ls):
    result = list(chain(*create_intervals(ls)))
    note(f"final: {result}")
    assert all(result[i] <= result[i + 1] for i in range(len(result) - 1))


@given(st.lists(st.integers(0, 2 ** 22)))
@settings(max_examples=250, verbosity=hypothesis.Verbosity.normal)
def test_exclusion(ls):
    result = list(chain(*create_intervals(ls)))
    assert all(map(lambda x: x not in result, ls))


@given(st.lists(st.integers(0, 2 ** 22)))
@settings(max_examples=500, verbosity=hypothesis.Verbosity.normal)
def test_range(ls):
    res = list(chain(*create_intervals(ls)))
    assert min(res) > 0
    assert max(res) // 0x40 <= (2 ** 13)

# NOT TRUE:
# @given(st.lists(st.integers(0x97, 2 ** 13-0x97)))
# def test_length(ls):
#     assume(ls != [0])
#     assume(ls != [1])
#     assume(ls != [2**13])
#     assert (len(set(ls))+1) == len(create_intervals(ls))


if __name__ == '__main__':
    print(f"max addres is {hex(2 ** 13)}")
    test_bad_blocks = [151, 152]
    result = create_intervals(test_bad_blocks)
    print(result)
    print([f"0x{x:x}/0x{x*0x40:x}" for x in test_bad_blocks], "gives")
    print([f"0x{x:x}" for x in list(chain(*result))])
    print([f"0x{x//0x40:x}" for x in list(chain(*result))])
