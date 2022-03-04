from progressbar import ProgressBar
import time
pbar = ProgressBar()

for page in pbar(range(10)):
    time.sleep(0.1)