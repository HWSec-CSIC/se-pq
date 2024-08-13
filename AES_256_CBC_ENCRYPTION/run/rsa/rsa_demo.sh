#!/bin/bash
#
#  SPIRS RoT DEMO  -- RSA
#
#  Created on: 16/02/2023 (santiago@imse-cnm.csic.es)
#
#################################################################################

clear
#
echo ""
echo ""
echo "  SPIRS-RoT: rsa_test"
echo "  -------------------"
echo "  Use of RSA encrypt & decrypt operation:"
echo ""
echo "  # bin/rsa_test -n 1" 
#
bin/rsa_test -n 1
#
read -s -r -p "Press any key to continue"
clear
# 
echo ""
echo ""
echo "  SPIRS-RoT: rsa_test"
echo "  -------------------"
echo "  Use of RSA encryp operation:"
echo ""
echo "  # bin/rsa_test -d 0" 
#
bin/rsa_test -d 0
#
echo "End RSA demo"
echo ""




