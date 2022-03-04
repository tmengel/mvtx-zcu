"""!@file ru_board_db_io.py : This module should give a nice interface to the DB
8/24/18:24
@author = Magnus (magnus.ersdal@uib.no)
"""

import base64
from datetime import datetime
import hmac
import time
import six
import dataset


class ITSdb:
    def __init__(self, board_id, dbname='/ITS_WP10_RU_board_badblocks.db'):
        self.dbname = dbname
        with dataset.connect('sqlite://' + self.dbname) as db:
            self.badblocks_table = db.get_table('bad_blocks')
            self.good_areas_table = db.get_table('good_memory_areas')
            self.hash_table = db.get_table('hashes')
            self.board_id_table = db.get_table('board_id')
            self.board_id = str(board_id)

    def add_board_id(self, board_serial_no):
        id = self.board_id_table.insert(
            dict(board_id=self.board_id, board_serial_no=board_serial_no))
        Hasher.hash_entry(self.board_id_table, id, board_serial_no, self.hash_table, tname=self.board_id_table.name)
        
    def add_bad_block(self, block_address, ts, fd):
        id = self.badblocks_table.insert(
            dict(board_id=self.board_id, block_addr=block_address, flash_device=fd, date=ts))
        Hasher.hash_entry(self.badblocks_table, id, ts, self.hash_table, tname=self.badblocks_table.name)

    def add_bad_blocks(self, block_table, fd):
        ts = self.timestamp()
        for adr in block_table:
            self.add_bad_block(adr, ts, fd)

    def get_bad_blocks(self):
        rows = self.get_newest_entries(self.badblocks_table)
        data = []
        for row in rows:
            Hasher.check_hash(row, table_name='bad_blocks', hashes_table=self.hash_table)
            data.append(row['block_addr'])
        return data

    def add_good_memory_areas(self, memareas, fd):
        """store 2-tuples of memory areas in the database"""
        ts = self.timestamp()
        for cnt, area in enumerate(memareas):
            self.add_good_memory_area(area, cnt, ts, fd)

    def add_good_memory_area(self, area, idx, ts, fd):
        id = self.good_areas_table.insert(dict(idx=idx, start=area[0], stop=area[1],
                                               startstop_type="page_address", date=ts,
                                               flash_device=fd,
                                               board_id=self.board_id))
        Hasher.hash_entry(self.good_areas_table, id, ts, self.hash_table, tname=self.good_areas_table.name)

    def get_good_memory_areas(self):
        row0 = self.good_areas_table.find_one(board_id=self.board_id, order_by='-date')
        rows = self.good_areas_table.find(board_id=self.board_id, date=row0['date'], order_by='-date')

        data = []
        date0 = row0['date']
        print("reading data from", datetime.fromtimestamp(date0))
        for row in rows:
            Hasher.check_hash(row, self.good_areas_table.name, self.hash_table)
            data.append((row['start'], row['stop']))
        return data

    def get_newest_entries(self, table):
        """order by date"""
        # elf.badblocks_table.find_one(board_id=self.board_id, order_by='-date')  # get most recent data point
        row0 = table.find_one(board_id=self.board_id, order_by='-date')
        rows = table.find(board_id=self.board_id, date=row0['date'], order_by='-date')
        return rows

    @staticmethod
    def timestamp():
        t = datetime.now()
        nixtime = time.mktime(t.timetuple())
        return nixtime


class Hasher:
    """collecting hashers in func"""
    key = b"wp10itsdaq_database"

    @staticmethod
    def hash_entry(datatable, idcode, ts, hashtable, tname):

        row = datatable.find_one(id=idcode)
        myhash = Hasher.hash_function(row)
        hashtable.insert(dict(table=tname,
                              entry_uid=row['id'],
                              timestamp=ts,
                              hash64=myhash))

    @staticmethod
    def hash_function(row):
        strs = []
        for dataname, datacontent in row.items():
            strs.append(str(dataname))
            strs.append(str(datacontent))
        # strdata = bytes(",".join(strs), format('utf-8'))
        strdata = six.b(",".join(strs))
        myhash = base64.b64encode(hmac.new(Hasher.key, strdata).digest())
        return myhash

    @staticmethod
    def check_hash(row_tocheck, table_name, hashes_table):
        hash_row = hashes_table.find_one(table=table_name, entry_uid=row_tocheck['id'])
        stored_hash = hash_row['hash64']
        if stored_hash == Hasher.hash_function(row_tocheck):
            print("# check complete")
        else:
            print("Warning, # check failure, be careful, data compromized")


if __name__ == '__main__':
    db = ITSdb("board_test")
    fake_bad = [1, 2, 333, 4, 5]
    fake_data = [(0, 1), (0, 43), (0, 1), (2, 1)]
    db.add_good_memory_areas(fake_data, fd=0)
    db.add_bad_blocks(fake_bad, fd=0)
    readout = db.get_good_memory_areas()
    print(list(readout))
    # db = ITSdb("board_test_id")
    readout = db.get_bad_blocks()
    print(list(readout))
