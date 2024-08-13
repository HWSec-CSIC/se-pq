#!/bin/sh -v

# BG NR LH 
# ========
#  0  0  0  -->  -g         Gray / Remote / Higher
#  0  0  1  -->  -g -l      Gray / Remote / Lower
#  1  0  0  -->             Binary / Remote / Higher
#  1  0  1  -->  -l         Binary / Remote / Lower

Board_ID=1
N_Runs=5
E_Tests=100
N_Tests=100
N_Cmps=640
E_Cmps=64
RC=9

date
#000 Gray/Remote/Higher
puf_reliability -g -d 1 -b $Board_ID -r $N_Runs -m $E_Tests -t $N_Tests -c $N_Cmps -e $E_Cmps -p $RC
# 
date
#001 Gray/Remote/Lower
puf_reliability -g -l -d 1 -b $Board_ID -r $N_Runs -m $E_Tests -t $N_Tests -c $N_Cmps -e $E_Cmps -p $RC
#
date
#100 Binary/Remote/Higher
puf_reliability -d 1 -b $Board_ID -r $N_Runs -m $E_Tests -t $N_Tests -c $N_Cmps -e $E_Cmps -p $RC
#
date
#101 Binary/Remote/Lower
puf_reliability -l -d 1 -b $Board_ID -r $N_Runs -m $E_Tests -t $N_Tests -c $N_Cmps -e $E_Cmps -p $RC
#
date


