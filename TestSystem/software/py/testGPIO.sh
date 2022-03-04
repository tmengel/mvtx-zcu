./testbench.py rdo comm _do_read_dp1 102400 hex
echo Disable DCLK
./testbench.py rdo write 7 2 0x01
./testbench.py rdo read 7 2
echo reset all prbs receivers
./testbench.py rdo write 7 0 0x1000
echo clear all prbs error counters
./testbench.py rdo write 7 0 0x0FFF
echo inject errors
./testbench.py rdo write 7 1 0x01 
./testbench.py rdo write 7 1 0x83
./testbench.py rdo write 7 1 0xC7
./testbench.py rdo write 7 1 0xEF
./testbench.py rdo write 7 1 0xFF
date
echo sleep 36000s
sleep 18000s
echo sleep done
date
nErrors=0
Result=$(./testbench.py rdo read 7 3)
if [ "$Result" = "30" ]
  then
    echo "Oke,           smaError $Result"
  else 
    echo "ERROR!!!!!!!!!   smaError $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 4)
if [ "$Result" = "30" ]
  then
    echo "Oke,   headerJ13_0Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 5)
if [ "$Result" = "24" ]
  then
    echo "Oke,   headerJ13_1Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 6)
if [ "$Result" = "18" ]
  then
    echo "Oke,   headerJ13_2Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 7)
if [ "$Result" = "12" ]
  then
    echo "Oke,   headerJ13_3Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 8)
if [ "$Result" = "6" ]
  then
    echo "Oke,   headerJ13_4Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 9)
if [ "$Result" = "30" ]
  then
    echo "Oke,PA3headerJ14_0Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 10)
if [ "$Result" = "24" ]
  then
    echo "Oke,PA3headerJ14_1Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 11)
if [ "$Result" = "18" ]
  then
    echo "Oke,PA3headerJ14_2Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 12)
if [ "$Result" = "12" ]
  then
    echo "Oke,PA3headerJ14_3Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 13)
if [ "$Result" = "6" ]
  then
    echo "Oke,PA3headerJ14_4Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 14)
if [ "$Result" = "30" ]
  then
    echo "Oke,         PA3_0Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 15)
if [ "$Result" = "24" ]
  then
    echo "Oke,         PA3_1Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 16)
if [ "$Result" = "18" ]
  then
    echo "Oke,         PA3_2Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 17)
if [ "$Result" = "12" ]
  then
    echo "Oke,         PA3_3Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 18)
if [ "$Result" = "6" ]
  then
    echo "Oke,         PA3_4Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 19)
if [ "$Result" = "30" ]
  then
    echo "Oke,         PA3_5Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_5Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 20)
if [ "$Result" = "24" ]
  then
    echo "Oke,         PA3_6Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_6Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 21)
if [ "$Result" = "18" ]
  then
    echo "Oke,         PA3_7Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_7Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 22)
if [ "$Result" = "12" ]
  then
    echo "Oke,         PA3_8Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_8Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 23)
if [ "$Result" = "6" ]
  then
    echo "Oke,         PA3_9Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_9Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 24)
if [ "$Result" = "30" ]
  then
    echo "Oke,        PA3_10Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_10Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 25)
if [ "$Result" = "24" ]
  then
    echo "Oke,        PA3_11Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_11Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 26)
if [ "$Result" = "30" ]
  then
    echo "Oke,       DCTRL_0Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 27)
if [ "$Result" = "24" ]
  then
    echo "Oke,       DCTRL_1Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 28)
if [ "$Result" = "18" ]
  then
    echo "Oke,       DCTRL_2Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 29)
if [ "$Result" = "12" ]
  then
    echo "Oke,       DCTRL_3Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 30)
if [ "$Result" = "6" ]
  then
    echo "Oke,       DCTRL_4Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 31)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKb_0Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 32)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKb_1Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 33)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKb_2Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 34)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKb_3Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 35)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKb_4Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 36)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKc_0Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 37)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKc_1Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 38)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKc_2Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 39)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKc_3Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 40)
if [ "$Result" = "0" ]
  then
    echo "Oke,       DCLKc_4Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 41)
if [ "$Result" = "30" ]
  then
    echo "Oke,         aux_0Error $Result"
  else
    echo "ERROR!!!!!!!!!    aux_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 42)
if [ "$Result" = "24" ]
  then
    echo "Oke,         aux_1Error $Result"
  else
    echo "ERROR!!!!!!!!!    aux_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 43)
if [ "$Result" = "18" ]
  then
    echo "Oke,         aux_2Error $Result"
  else
    echo "ERROR!!!!!!!!!    aux_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 44)
if [ "$Result" = "12" ]
  then
    echo "Oke,         aux_3Error $Result"
  else
    echo "ERROR!!!!!!!!!    aux_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 45)
if [ "$Result" = "30" ]
  then
    echo "Oke,          pu_0Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 46)
if [ "$Result" = "24" ]
  then
    echo "Oke,          pu_1Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 47)
if [ "$Result" = "18" ]
  then
    echo "Oke,          pu_2Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 48)
if [ "$Result" = "12" ]
  then
    echo "Oke,          pu_3Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 49)
if [ "$Result" = "6" ]
  then
    echo "Oke,          pu_4Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 50)
if [ "$Result" = "12" ]
  then
    echo "Oke,          pu_5Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_5Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 51)
if [ "$Result" = "18" ]
  then
    echo "Oke,          pu_6Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_6Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 52)
if [ "$Result" = "24" ]
  then
    echo "Oke,          pu_7Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_7Error $Result"
    ((nErrors++))
  fi
echo "Number of faulty channels=$nErrors"
nErrorsOld="$nErrors"
nErrors=0
echo Enable DCLK
./testbench.py rdo write 7 2 0x00
./testbench.py rdo read 7 2
echo reset all prbs receivers
./testbench.py rdo write 7 0 0x1000
echo clear all prbs error counters
./testbench.py rdo write 7 0 0x0FFF
echo inject errors
./testbench.py rdo write 7 1 0x01 
./testbench.py rdo write 7 1 0x83
./testbench.py rdo write 7 1 0xC7
./testbench.py rdo write 7 1 0xEF
./testbench.py rdo write 7 1 0xFF
date
echo sleep 36000s
sleep 18000s
echo sleep done
date
Result=$(./testbench.py rdo read 7 3)
if [ "$Result" = "30" ]
  then
    echo "Oke,           smaError $Result"
  else 
    echo "ERROR!!!!!!!!!   smaError $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 4)
if [ "$Result" = "30" ]
  then
    echo "Oke,   headerJ13_0Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 5)
if [ "$Result" = "24" ]
  then
    echo "Oke,   headerJ13_1Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 6)
if [ "$Result" = "18" ]
  then
    echo "Oke,   headerJ13_2Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 7)
if [ "$Result" = "12" ]
  then
    echo "Oke,   headerJ13_3Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 8)
if [ "$Result" = "6" ]
  then
    echo "Oke,   headerJ13_4Error $Result"
  else
    echo "ERROR!!!!!!!!!   headerJ13_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 9)
if [ "$Result" = "30" ]
  then
    echo "Oke,PA3headerJ14_0Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 10)
if [ "$Result" = "24" ]
  then
    echo "Oke,PA3headerJ14_1Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 11)
if [ "$Result" = "18" ]
  then
    echo "Oke,PA3headerJ14_2Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 12)
if [ "$Result" = "12" ]
  then
    echo "Oke,PA3headerJ14_3Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 13)
if [ "$Result" = "6" ]
  then
    echo "Oke,PA3headerJ14_4Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3headerJ14_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 14)
if [ "$Result" = "30" ]
  then
    echo "Oke,         PA3_0Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 15)
if [ "$Result" = "24" ]
  then
    echo "Oke,         PA3_1Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 16)
if [ "$Result" = "18" ]
  then
    echo "Oke,         PA3_2Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 17)
if [ "$Result" = "12" ]
  then
    echo "Oke,         PA3_3Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 18)
if [ "$Result" = "6" ]
  then
    echo "Oke,         PA3_4Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 19)
if [ "$Result" = "30" ]
  then
    echo "Oke,         PA3_5Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_5Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 20)
if [ "$Result" = "24" ]
  then
    echo "Oke,         PA3_6Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_6Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 21)
if [ "$Result" = "18" ]
  then
    echo "Oke,         PA3_7Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_7Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 22)
if [ "$Result" = "12" ]
  then
    echo "Oke,         PA3_8Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_8Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 23)
if [ "$Result" = "6" ]
  then
    echo "Oke,         PA3_9Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_9Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 24)
if [ "$Result" = "30" ]
  then
    echo "Oke,        PA3_10Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_10Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 25)
if [ "$Result" = "24" ]
  then
    echo "Oke,        PA3_11Error $Result"
  else
    echo "ERROR!!!!!!!!!   PA3_11Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 26)
if [ "$Result" = "30" ]
  then
    echo "Oke,       DCTRL_0Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 27)
if [ "$Result" = "24" ]
  then
    echo "Oke,       DCTRL_1Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 28)
if [ "$Result" = "18" ]
  then
    echo "Oke,       DCTRL_2Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 29)
if [ "$Result" = "12" ]
  then
    echo "Oke,       DCTRL_3Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 30)
if [ "$Result" = "6" ]
  then
    echo "Oke,       DCTRL_4Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCTRL_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 31)
if [ "$Result" = "30" ]
  then
    echo "Oke,       DCLKb_0Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 32)
if [ "$Result" = "24" ]
  then
    echo "Oke,       DCLKb_1Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 33)
if [ "$Result" = "18" ]
  then
    echo "Oke,       DCLKb_2Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 34)
if [ "$Result" = "12" ]
  then
    echo "Oke,       DCLKb_3Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 35)
if [ "$Result" = "6" ]
  then
    echo "Oke,       DCLKb_4Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKb_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 36)
if [ "$Result" = "30" ]
  then
    echo "Oke,       DCLKc_0Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 37)
if [ "$Result" = "24" ]
  then
    echo "Oke,       DCLKc_1Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 38)
if [ "$Result" = "18" ]
  then
    echo "Oke,       DCLKc_2Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 39)
if [ "$Result" = "12" ]
  then
    echo "Oke,       DCLKc_3Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 40)
if [ "$Result" = "6" ]
  then
    echo "Oke,       DCLKc_4Error $Result"
  else
    echo "ERROR!!!!!!!!!  DCLKc_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 41)
if [ "$Result" = "30" ]
  then
    echo "Oke,         aux_0Error $Result"
  else
    echo "ERROR!!!!!!!!!    aux_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 42)
if [ "$Result" = "24" ]
  then
    echo "Oke,         aux_1Error $Result"
  else
    echo "ERROR!!!!!!!!!    aux_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 43)
if [ "$Result" = "18" ]
  then
    echo "Oke,         aux_2Error $Result"
  else
    echo "ERROR!!!!!!!!!    aux_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 44)
if [ "$Result" = "12" ]
  then
    echo "Oke,         aux_3Error $Result"
  else
    echo "ERROR!!!!!!!!!    aux_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 45)
if [ "$Result" = "30" ]
  then
    echo "Oke,          pu_0Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_0Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 46)
if [ "$Result" = "24" ]
  then
    echo "Oke,          pu_1Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_1Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 47)
if [ "$Result" = "18" ]
  then
    echo "Oke,          pu_2Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_2Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 48)
if [ "$Result" = "12" ]
  then
    echo "Oke,          pu_3Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_3Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 49)
if [ "$Result" = "6" ]
  then
    echo "Oke,          pu_4Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_4Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 50)
if [ "$Result" = "12" ]
  then
    echo "Oke,          pu_5Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_5Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 51)
if [ "$Result" = "18" ]
  then
    echo "Oke,          pu_6Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_6Error $Result"
    ((nErrors++))
  fi
Result=$(./testbench.py rdo read 7 52)
if [ "$Result" = "24" ]
  then
    echo "Oke,          pu_7Error $Result"
  else
    echo "ERROR!!!!!!!!!     pu_7Error $Result"
    ((nErrors++))
  fi
echo "Number of faulty channels with DCLK  enabled =$nErrors"
echo "Number of faulty channels with DCLK disabled =$nErrorsOld"
