#! /bin/bash
# The script calculates the number of essential bits

for FILE in "$@"
do
    if [[ $FILE == *.ebd ]]; then
        #set -e;
        ESS=`sed 1,8d ${FILE} | tr -cd 1 | wc -m`
        TOT=`sed 1,8d ${FILE} | wc -m`
        echo "${FILE} essential bits ${ESS}/${TOT} = `echo "scale=2 ; (100*${ESS}/${TOT})" | bc`%"
    else
        echo "File ${FILE} is not a valid ebd file"
        echo "Usage: "
        echo ">> source essential_bits.sh <filename>.ebd"
    fi
done
