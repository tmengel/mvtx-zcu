"""!@file test_ecc_logs.py : Purpose
8/16/18:16
@author = Magnus (magnus.ersdal@uib.no)
"""

filen = "../logs/spam.log"

with open(filen, 'r') as f:
    lines = f.readlines()

lines.reverse()

pages = []
pagecount = 0
for i, line in enumerate(lines):
    if "locations" in line:
        print(line)
        print(prevline)
        if len(prevline) > 49:
            pages.append([int(x) for x in prevline[46:].strip()[1:-1].split(",")])
    if len(pages) >= 4:
        break
    prevline = line
pagesets = [set(x) for x in pages]
intersections = set(pagesets[0]).intersection(*pagesets)
print(intersections)
if intersections == pagesets[0]:
    print("all is equal")

if intersections == set(range(0xc003, 0xd6c2)):
    print("in all the bloody places")

derivative = []
x0 = list(intersections)[0]
lp = list(pages[0])
for x in lp[1:]:
    derivative.append(abs(x0 - x))
    x0 = x
print(max(derivative), min(derivative), min(lp) - lp[0], max(lp) - lp[0])
print(max(derivative), min(derivative), hex(min(lp)), hex(max(lp)))

for p in pages:
    for i, x in enumerate(p):
        if x < 0xc000:
            print("WTF", i)
