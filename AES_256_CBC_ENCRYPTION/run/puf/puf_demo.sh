#!/bin/bash
#
#  SPIRS RoT DEMO  -- PUF
#
#  Created on: 16/02/2023 (santiago@imse-cnm.csic.es)
#
#################################################################################

clear
#
echo ""
echo ""
echo "  SPIRS-RoT: PUF Test"
echo "  -------------------"
echo "  Use of the PUF as ID Generator"
echo ""
echo "  # bin/puf_getdata -t 5 -c 64 -d 2" 
#
bin/puf_getdata -t 4 -c 64 -d 2 
#
read -s -r -p "Press any key to continue"
clear
# 
echo ""
echo ""
echo "  SPIRS-RoT: PUF Test"
echo "  -------------------"
echo "  Use of the Challenge Selection Mechanism when generating a 64-bit key using 192 bits "
echo "  from 48 comparisons (without selecting challenges) and a repetition code 3"
echo ""
echo "  #  bin/puf_reliability -c 48 -e 0 -d 5 -t 25 -r 1 -p 3" 
#
 bin/puf_reliability -c 48 -e 0 -d 5 -t 25 -r 1 -p 3
#
read -s -r -p "Press any key to continue"
clear
#
echo ""
echo ""
echo "  SPIRS-RoT: PUF Test"
echo "  -------------------"
echo "  Use of the Challenge Selection Mechanism when generating a 64-bit key using 192 bits "
echo "  from the best 48 of 64 comparisons (selecting challenges) and a repetition code 3"
echo ""
echo "  #   bin/puf_reliability -c 64 -e 16 -d 5 -t 25 -r 1 -p 3" 
#
 bin/puf_reliability -c 64 -e 16 -d 5 -t 25 -r 1 -p 3
#
read -s -r -p "Press any key to continue"
clear
#
echo ""
echo ""
echo "  SPIRS-RoT: PUF Test"
echo "  -------------------"
echo "  Statistical analysis of the use of the PUF as ID generator"
echo ""
echo "  # bin/puf_test -c 240 -k 64" 
#
bin/puf_test -c 240 -k 64 
#
echo "End PUF demo"
echo ""
exit


