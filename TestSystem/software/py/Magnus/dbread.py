"""
@brief Examples of database read/write functions not used in production code.

"""

import json
import dataset
from datetime import datetime
from json_test import hash_function

db = dataset.connect('sqlite:///ITS_WP10_RU_board_badblocks.db')

print(db.tables)

print(db['good_memory_areas'].columns)
print(list(db['good_memory_areas'].all()))
print(list(db['good_memory_areas'].distinct('date')))
print(db['bad_blocks'].columns)


def check_hash(row_tocheck,table_name, hashes_table):
    """reimplemented in the Hasher class in ru_board_db_io.py"""
    hash_row = hashes_table.find_one(table=table_name,entry_uid=row_tocheck['id'])
    stored_hash = hash_row['hash64']
    if stored_hash == hash_function(row_tocheck, b"wp10itsdaq_database"):
        print("# check complete")
    else:
        print("Warning, # check failure")

areas = db.load_table('good_memory_areas')
hashes = db.load_table('hashes')
print("all:",list(hashes.all()))
print("allhashes:",list(hashes.find()))
for row in hashes.all():
     print(row['table'],row['entry_uid'], row['hash64'])
#table.find(age={'>=': 70})
print(list(areas.columns))
print("found:",list(areas.find(areas.table.columns.date > 2)))

# http://docs.sqlalchemy.org/en/latest/core/tutorial.html#selecting
statement = 'SELECT * from "good_memory_areas" WHERE date > 0' # works for seconds.
for row in db.query(statement):
    print(hex(row['start']), ":", hex(row['stop']), datetime.fromtimestamp(row['date']))


statement = 'SELECT * from "good_memory_areas" WHERE board_id = 0' # works for seconds.
for row in db.query(statement):
    print("board_id = 0" ,row['id'],hex(row['start']), ":", hex(row['stop']), datetime.fromtimestamp(row['date']))


statement = 'SELECT * from "bad_blocks"' # try to select board id and bad blocks
for row in db.query(statement):
    print("board_id = 0" ,row['id'], row['block_addr'])
