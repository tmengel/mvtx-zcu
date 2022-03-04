"""
author: magnus.ersdal@uib.no
convenience functions to interface with the bad-blocks database.
why a database? : because a database is a queryable, organized datastore.
why sqlite? : because its easily available, has good support, small footprint and is portable
also has public domain licensing (mysql is gpl2
sqlite db supports multiple readers, but only single changer.

usage:
download the database from cernbox, in the folder ITS-WP10 / Hardware / Test_System
con = sqlite3.connect('path_to_badblocks.db')
testing can be done in memory:
con2 = sqlite3.connect(':memory:')

bad_block_dict: Dict[int, List[int]]
e.g {0: [1,2,3,4], 1:[1334,1335]}, the key is the flash device and values are the bad blocks
store_bad_blocks("board id or dna", , con)

good_blocks = get_good_blocks(con, '7')
"""

import sqlite3
import time
from datetime import datetime
from itertools import tee
from typing import Dict, List

import pandas as pd
from pandas.io.sql import DatabaseError



def pairwise(iterable):
    """s -> (s0,s1), (s1,s2), (s2, s3), ..."""
    a, b = tee(iterable)
    next(b, None)
    return zip(a, b)


def clear_leading_zeroes(x: str):
    return x.lstrip('0')


# bb_raw is short for bad_blocks
def get_bad_blocks(conn) -> pd.DataFrame:
    """get dataframe table of bad_blocks from database"""
    bb_raw = pd.read_sql_query('SELECT * FROM bad_blocks', conn)
    bb_nice = format_table_nicely(bb_raw)
    return bb_nice


def format_table_nicely(table):
    """strip leading zeros in board_id name and show proper dates"""
    bb_date = table
    bb_date['date'] = table['date'].apply(datetime.fromtimestamp)
    bb_strp = bb_date
    bb_strp['board_id'] = bb_strp['board_id'].apply(clear_leading_zeroes)
    bb_noindex = bb_date[['board_id', 'block_addr', 'flash_device', 'date']]
    clean_table = bb_noindex.drop_duplicates()

    return clean_table


def get_dna_mapping(id_or_dna, conn) -> str:
    """get the map of id -> dna, or dna -> id automatically from the input and database"""
    raw = pd.read_sql_query('SELECT * FROM board_id', conn)
    # clear leading zeroes:
    tmp = raw
    tmp['board_serial_no'] = tmp['board_serial_no'].apply(clear_leading_zeroes)
    # make sure string (dna is too long for C int class)
    iddna = str(id_or_dna)
    # row = tmp.query('board_id == @iddna | board_serial_no == @iddna')
    # row = tmp[(tmp.board_id == iddna) | (tmp.board_serial_no == iddna)]
    row = tmp.query('board_id == @iddna or board_serial_no == @iddna')
    if row.empty:
        return ""
    b_serial, b_dna = row['board_id'].iloc[0], row['board_serial_no'].iloc[0]
    # return the one that is not the same as the name
    if b_serial != iddna:
        return b_serial
    else:
        return b_dna


def add_dna_mapping(id, dna, conn) -> None:
    """add a new id -> dna mapping"""
    try:
        existing = get_dna_mapping(id, conn)
    except DatabaseError:
        existing = False  # ignore database read error. Mostly to allow dummy tables

    if existing:
        estr = f"value already existing as a mapping between {id} and {existing}. " \
            f"modifying these entries via this function ({add_dna_mapping.__name__}) is not allowed... aborting"
        raise TypeError(estr)
    # this adds the data to the database
    with conn:
        _ = pd.DataFrame({'board_id': str(dna),
                          'board_serial_no': str(id)},
                         index=[0]).to_sql('board_id', conn, index_label='id', if_exists='append', index=False)  # dummy board_id


def get_bad_blocks_of_board(board_id: str, conn, exclusive_name=False):
    """
    read out bad blocks of a specific board id. looks up for both serial and dna as default.
    exclusive_name flag disallows looking up the board_id mapping and finding other
    entries"""
    othername = get_dna_mapping(board_id, conn)
    # would work if no leading zeros in database
    # lookup = pd.read_sql_query('SELECT * from bad_blocks '
    #                            'WHERE board_id==@a OR board_id==@b', conn,
    #                            params={'a': board_id,
    #                                    'b': othername}
    #                            )
    name = str(board_id)
    othername = get_dna_mapping(name, conn)
    if exclusive_name:
        names = [name]
    else:
        names = [name, othername]
    bb = get_bad_blocks(conn)
    # filtered_bb = bb.query('board_id == @name')
    lookup = bb[bb.board_id.isin(names)]
    if lookup.empty:
        print(f"failed to find {board_id} or {othername}")
        raise LookupError(f"failed to find {board_id} or {othername}")

    return lookup


def get_first_good_blocks(board_bad_blocks):
    """finds the first block addresses where you can put the firmware in the flash"""
    n_blocks = 3  # firmware, scrubbing, and golden firmware
    fdd = board_bad_blocks.sort_values(by=['block_addr'])
    all_bad_blocks = pd.DataFrame(fdd['block_addr'].drop_duplicates())
    all_bad_blocks['block_addr'] = pd.to_numeric(all_bad_blocks['block_addr'])
    wanted_blocks = [0x100 * i for i in range(1, 31)]  # arbitrary chosen 0x100 in distance. could be smaller.
    locations = []

    # edge case no bad blocks
    if len(all_bad_blocks) == 0:
        return wanted_blocks[0:n_blocks]
    # edge case only one bad block
    if len(all_bad_blocks) == 1:
        # only one bad block
        bad_blocks = all_bad_blocks.to_list()
        item = bad_blocks[0]
        if item < min(wanted_blocks):
            return wanted_blocks[0:n_blocks]
        else:
            # [0x100, item), (item, max]
            intervals = [pd.Interval(0x100, item, closed='left'),
                         pd.Interval(item, max(wanted_blocks), closed='right')]
            for iv in intervals:
                for c, d in pairwise(wanted_blocks):
                    if c in iv and d in iv:
                        locations.append(c)
                    if len(locations) >= n_blocks:
                        break
            return locations[0:n_blocks]

        # end edge case
    # normal case, 2 or more bad blocks
    filtered_bad_blocks = list(all_bad_blocks.query('block_addr >= 0x100')['block_addr'])
    # -1/+1 to include 0x100 and 2**13-0x100 (max addr) in valid ranges (always)
    bb_with_startstop = [0x100 - 1] + filtered_bad_blocks + [2 ** 13 - 0x100 + 1]
    for a, b in pairwise(bb_with_startstop):
        # (bad, bad)
        iv = pd.Interval(a, b, closed='neither')  # {x: a<x<b} with neither closed it is an open interval
        for c, d in pairwise(wanted_blocks):
            if c in iv and d in iv:
                locations.append(c)
        if len(locations) >= n_blocks:
            break

    return locations[0:n_blocks]


def show_all_db_names(conn):
    """display names in the database, shows the unmapped names first, then the names with  id->dna mapping"""
    idmap = pd.read_sql_query('SELECT DISTINCT board_id, board_serial_no from board_id', conn)
    named_data = pd.read_sql_query('SELECT DISTINCT board_id from bad_blocks', conn)
    unmapped_names = named_data[
        ~named_data['board_id'].isin(idmap['board_id']) &
        ~named_data['board_id'].isin(idmap['board_serial_no'])]
    namelist = []
    namelist.extend(list(unmapped_names['board_id'].apply(clear_leading_zeroes)))
    namelist.extend(list([f"{x[0].lstrip('0'):<4}, {x[1]}" for x in idmap[['board_serial_no', 'board_id']].values]))
    print("\n".join(namelist))


def show_all_names_with_data(conn):
    """display names that have data entries"""
    lookup = pd.read_sql_query('SELECT DISTINCT board_id from bad_blocks', conn)
    print(lookup)


def get_good_blocks(board_id, conn):
    """this is the function you should use to get the good blocks of a board."""
    return get_first_good_blocks(get_bad_blocks_of_board(board_id, conn))


def store_bad_blocks(id, bad_blocks_d: Dict[int, List[int]], conn):
    """use this to store the bad block data
    requires pandas and tables libraries"""

    # malformed dict checking (got to catch them all coding) # https://www.reddit.com/r/ProgrammerHumor/comments/1xeew9/exceptions_gotta_catch_em_all/
    try:
        for flash_dev, bad_blocks_l in bad_blocks_d.items():
            if type(flash_dev) != int:
                raise TypeError("malformed bad block dictionary")
            if type(bad_blocks_l) != list:
                raise TypeError("malformed bad block dictionary")
            if bad_blocks_l:  # must not be empty for these checks.
                if max(bad_blocks_l) > 2 ** 13:
                    raise TypeError("malformed bad block dictionary")
                if min(bad_blocks_l) <= 1:
                    # 0 and 1 should not even be read, the first block is guaranteed good by the manufacturer
                    raise TypeError("malformed bad block dictionary")
    except TypeError as e:
        # temporarily store the bad blocks dict, so we don't loose it.
        # it may be mal-formed, and we don't want a mal-formed table entry, so to make sure we
        # get no data loss, we store it temporarily as a hdf file.
        store = pd.HDFStore('tmp.h5', 'a')
        time_stamp = datetime.now().strftime('%Y-%m-%dT%H%M%S')  # ISO 8601
        tmpname = 'bad_blocks_d_' + time_stamp
        store[tmpname] = pd.DataFrame(bad_blocks_d)
        store.close()
        raise e

    t = datetime.now()
    nixtime = time.mktime(t.timetuple())
    data = {}
    flash_device = []
    bad_blocks = []
    size = 0
    for flash_dev, bad_blocks_l in bad_blocks_d.items():
        # convert dict into tables
        size += len(bad_blocks_l)
        flash_device.extend([flash_dev] * len(bad_blocks_l))
        bad_blocks.extend(bad_blocks_l)

    data['block_addr'] = bad_blocks
    data['board_id'] = [str(id)] * size
    data['flash_device'] = flash_device
    data['date'] = [nixtime] * size
    table = pd.DataFrame(data)
    with conn:
        table.to_sql('bad_blocks', conn, index_label='id', if_exists='append', index=False)
    # lookup2 = pd.read_sql_query('SELECT * from bad_blocks', conn)
    return table


def already_exists(board_id, conn):
    alt_name = get_dna_mapping(board_id, conn)

    name = str(board_id)
    names = [name, alt_name]
    bb = get_bad_blocks(conn)
    lookup = bb[bb.board_id.isin(names)]
    if lookup.empty:
        print("no data for board called", board_id)
        b_val = False
    else:
        print(name, "has data in db")
        b_val = True
    return b_val


if __name__ == '__main__':
    con = sqlite3.connect('../dbs/badblocks.db')
    bb = get_bad_blocks_of_board("19809458498735734293843165701", con)
    good_blocks = get_good_blocks('7', con)
    print(*map(hex, good_blocks))
    good_blocks = get_good_blocks(22, con)
    print(*map(hex, good_blocks))
    con2 = sqlite3.connect(':memory:')
    store_bad_blocks("non", {0: [0, 1, 2, 3, 4], 1: [0, 1, 3, 4]}, con2)
    store_bad_blocks("non", {0: [0, 1, 10, 0x100], 1: [0, 1, 3, 4]}, con2)
    store_bad_blocks("non", {0: [0, 1, 2, 0x99], 1: [0, 1, 3, 4]}, con2)
    add_dna_mapping('non', 'non', con2)  # dummy
    add_dna_mapping('non2', 'non2', con2)  # should raise

    lookup2 = pd.read_sql_query('SELECT * from bad_blocks', con2)
    good_blocks2 = get_good_blocks("non", con2)
    print(*map(hex, good_blocks2))
    already_exists("7", con)
