#!/bin/bash

#creates sockit with tcl script in background

export ZCUDIR=/home/ALICE/ZCU102_CRU/software/tcl
cd $ZCUDIR

vivado -mode tcl -source xilinx_tcpserv.tcl &

xfce4-terminal &
sleep 5

xdotool type 'ready'
