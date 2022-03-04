./testbench.py rdo comm _do_read_dp1 102400 hex
./testbench.py rdo mgt-test reset_all
./testbench.py rdo mgt-test read-status
./testbench.py rdo mgt-test enable-errors
./testbench.py rdo mgt-test read-prbs-err
printf "0x%x\n" `./testbench.py rdo mgt-test read-prbs-locked`
./testbench.py rdo drp_ctrl read-prbs-counter 0
./testbench.py rdo drp_ctrl read-prbs-counter 1
./testbench.py rdo drp_ctrl read-prbs-counter 2
./testbench.py rdo drp_ctrl read-prbs-counter 3
./testbench.py rdo drp_ctrl read-prbs-counter 4
./testbench.py rdo drp_ctrl read-prbs-counter 5
./testbench.py rdo drp_ctrl read-prbs-counter 6
./testbench.py rdo drp_ctrl read-prbs-counter 7
./testbench.py rdo drp_ctrl read-prbs-counter 8
./testbench.py rdo drp_ctrl read-prbs-counter 9
./testbench.py rdo drp_ctrl read-prbs-counter 10
./testbench.py rdo drp_ctrl read-prbs-counter 11
./testbench.py rdo drp_ctrl read-prbs-counter 12
./testbench.py rdo drp_ctrl read-prbs-counter 13
./testbench.py rdo drp_ctrl read-prbs-counter 14
./testbench.py rdo drp_ctrl read-prbs-counter 15
./testbench.py rdo drp_ctrl read-prbs-counter 16
./testbench.py rdo drp_ctrl read-prbs-counter 17
./testbench.py rdo drp_ctrl read-prbs-counter 18
./testbench.py rdo drp_ctrl read-prbs-counter 19
./testbench.py rdo drp_ctrl read-prbs-counter 20
./testbench.py rdo drp_ctrl read-prbs-counter 21
./testbench.py rdo drp_ctrl read-prbs-counter 22
./testbench.py rdo drp_ctrl read-prbs-counter 23
./testbench.py rdo drp_ctrl read-prbs-counter 24
./testbench.py rdo drp_ctrl read-prbs-counter 25
./testbench.py rdo drp_ctrl read-prbs-counter 26
./testbench.py rdo drp_ctrl read-prbs-counter 27
./testbench.py rdo mgt-test force_error
date
echo sleep 36000s
sleep 1s
echo sleep done
date
./testbench.py rdo drp_ctrl read-prbs-counter 0
./testbench.py rdo drp_ctrl read-prbs-counter 1
./testbench.py rdo drp_ctrl read-prbs-counter 2
./testbench.py rdo drp_ctrl read-prbs-counter 3
./testbench.py rdo drp_ctrl read-prbs-counter 4
./testbench.py rdo drp_ctrl read-prbs-counter 5
./testbench.py rdo drp_ctrl read-prbs-counter 6
./testbench.py rdo drp_ctrl read-prbs-counter 7
./testbench.py rdo drp_ctrl read-prbs-counter 8
./testbench.py rdo drp_ctrl read-prbs-counter 9
./testbench.py rdo drp_ctrl read-prbs-counter 10
./testbench.py rdo drp_ctrl read-prbs-counter 11
./testbench.py rdo drp_ctrl read-prbs-counter 12
./testbench.py rdo drp_ctrl read-prbs-counter 13
./testbench.py rdo drp_ctrl read-prbs-counter 14
./testbench.py rdo drp_ctrl read-prbs-counter 15
./testbench.py rdo drp_ctrl read-prbs-counter 16
./testbench.py rdo drp_ctrl read-prbs-counter 17
./testbench.py rdo drp_ctrl read-prbs-counter 18
./testbench.py rdo drp_ctrl read-prbs-counter 19
./testbench.py rdo drp_ctrl read-prbs-counter 20
./testbench.py rdo drp_ctrl read-prbs-counter 21
./testbench.py rdo drp_ctrl read-prbs-counter 22
./testbench.py rdo drp_ctrl read-prbs-counter 23
./testbench.py rdo drp_ctrl read-prbs-counter 24
./testbench.py rdo drp_ctrl read-prbs-counter 25
./testbench.py rdo drp_ctrl read-prbs-counter 26
./testbench.py rdo drp_ctrl read-prbs-counter 27


