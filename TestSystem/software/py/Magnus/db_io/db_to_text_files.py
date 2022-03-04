import dataset
from datetime import datetime
import os
from progressbar import ProgressBar

if __name__ == '__main__':
    db_path = "../ITS_WP10_RU_board_badblocks.db" # your db name here!
    # 1 : get board ids
    qdb = dataset.connect('sqlite:///' + db_path)

    statement = 'SELECT board_id from "bad_blocks"'  # try to select board id and bad blocks
    uids = list({row['board_id'] for row in qdb.query(statement)})
    print("uids:", uids)
    print(f"making {len(uids)} files")
    pbar = ProgressBar()
    for id in pbar(uids):
        all_of_id = 'SELECT t.* FROM bad_blocks t WHERE board_id is "' + id + '" ORDER BY flash_device ASC, date DESC'
        rows_of_id = qdb.query(all_of_id)
        stringslol = ["WARNING: FOR DEBUG USE ***ONLY*** USE DATABASE FOR PRODUCTION\n"'uid, ', 'block address, ', 'flash device, ', 'date', '\n']
        for row in rows_of_id:
            extension = (f"{row['id']:4}, {row['block_addr']:6}, {row['flash_device']:2} "
                         + datetime.fromtimestamp(row['date']).strftime("%Y-%m-%d_%H-%M-%S") + "\n")
            stringslol.append(extension)
        stringslol.append("WARNING: FOR DEBUG USE ***ONLY*** USE DATABASE FOR PRODUCTION\n")
        # print(*stringslol)
        filename = id +  datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + ".txt"
        script_dir = os.path.dirname(__file__)
        rel_path= "outputfiles/"+filename
        absfilepath = os.path.join(script_dir, rel_path)
        with open(absfilepath, 'w+') as f:
            f.writelines(stringslol)