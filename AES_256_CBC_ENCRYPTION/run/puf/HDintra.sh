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

date
#000 Gray/Remote/Higher
puf_HDintra -g -d 1 -b $Board_ID -r $N_Runs -m $E_Tests -t $N_Tests -c $N_Cmps -e $E_Cmps
# 
date
#001 Gray/Remote/Lower
puf_HDintra -g -l -d 1 -b $Board_ID -r $N_Runs -m $E_Tests -t $N_Tests -c $N_Cmps -e $E_Cmps
#
date
#100 Binary/Remote/Higher
puf_HDintra -d 1 -b $Board_ID -r $N_Runs -m $E_Tests -t $N_Tests -c $N_Cmps -e $E_Cmps
#
date
#101 Binary/Remote/Lower
puf_HDintra -l -d 1 -b $Board_ID -r $N_Runs -m $E_Tests -t $N_Tests -c $N_Cmps -e $E_Cmps
#
date


