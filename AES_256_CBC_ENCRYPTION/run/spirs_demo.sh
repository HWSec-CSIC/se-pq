#!/bin/bash
#
#  SPIRS RoT DEMO
#
#  Created on: 16/02/2023 (santiago@imse-cnm.csic.es)
#
#################################################################################
#
clear
echo ""
echo "  SPIRS-RoT DEMO"
echo "  =============="
#
run/aes/aes_demo.sh
#
read -s -r -p "Press any key to continue"
# 
run/rsa/rsa_demo.sh
#
read -s -r -p "Press any key to continue"
# 
run/sha2/sha2_demo.sh
#
read -s -r -p "Press any key to continue"
# 
run/puf/puf_demo.sh
#
read -s -r -p "Press any key to continue"
# 
run/puf/trng_demo.sh
#
#read -s -r -p "Press any key to continue"
# 
echo "End SPIRS DEMO"



